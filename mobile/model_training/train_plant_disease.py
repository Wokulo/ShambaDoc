"""
ShambaDoc — Crop Disease Model Trainer
======================================

Trains a MobileNetV2 transfer-learning classifier and exports
`plant_disease.tflite` + `labels.txt` for the Flutter app.

The 26 target classes span three public datasets, all available through
TensorFlow Datasets (no Kaggle auth / manual downloads required):

  * plant_village  -> Maize, Tomato, Potato, Pepper  (18 classes)
  * beans          -> Bean                            (3 classes)
  * cassava        -> Cassava                         (5 classes)

CRITICAL CONTRACT with the app (mobile/lib/ai/tflite_service.dart):
  * Input : float32 [1, 224, 224, 3], RGB, values in [0, 1]
            (the app divides each pixel by 255 before inference)
  * Output: float32 [1, 26], softmax scores; argmax index -> labels.txt line
  * labels.txt line order MUST equal CANONICAL_LABELS below, or every
    prediction is mislabeled.

Run on Google Colab (free GPU):
  !pip -q install tensorflow_datasets
  !python train_plant_disease.py
Then download `plant_disease.tflite` + `labels.txt` and drop them into
  mobile/assets/models/

Runtime: ~20-40 min on a Colab T4 GPU.
"""

import os
import numpy as np
import tensorflow as tf
import tensorflow_datasets as tfds

# ---------------------------------------------------------------------------
# 1. Canonical label order — MUST match mobile/assets/models/labels.txt exactly
# ---------------------------------------------------------------------------
CANONICAL_LABELS = [
    "Maize___Common_rust",
    "Maize___Northern_Leaf_Blight",
    "Maize___Gray_Leaf_Spot",
    "Maize___healthy",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Bacterial_spot",
    "Tomato___Yellow_Leaf_Curl_Virus",
    "Tomato___Mosaic_virus",
    "Tomato___Target_Spot",
    "Tomato___healthy",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Bean___Angular_leaf_spot",
    "Bean___Bean_rust",
    "Bean___healthy",
    "Cassava___Mosaic_disease",
    "Cassava___Brown_streak_disease",
    "Cassava___Bacterial_blight",
    "Cassava___Green_mite",
    "Cassava___healthy",
    "Pepper___Bacterial_spot",
    "Pepper___healthy",
]
NUM_CLASSES = len(CANONICAL_LABELS)
assert NUM_CLASSES == 26, f"expected 26 classes, got {NUM_CLASSES}"
LABEL_TO_INDEX = {name: i for i, name in enumerate(CANONICAL_LABELS)}

# ---------------------------------------------------------------------------
# 2. Per-dataset source-class -> canonical-label mappings (matched by NAME,
#    so the script is robust to tfds label-index changes)
# ---------------------------------------------------------------------------
PLANT_VILLAGE_MAP = {
    "Corn_(maize)___Common_rust_": "Maize___Common_rust",
    "Corn_(maize)___Northern_Leaf_Blight": "Maize___Northern_Leaf_Blight",
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": "Maize___Gray_Leaf_Spot",
    "Corn_(maize)___healthy": "Maize___healthy",
    "Tomato___Early_blight": "Tomato___Early_blight",
    "Tomato___Late_blight": "Tomato___Late_blight",
    "Tomato___Leaf_Mold": "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot": "Tomato___Septoria_leaf_spot",
    "Tomato___Bacterial_spot": "Tomato___Bacterial_spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": "Tomato___Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus": "Tomato___Mosaic_virus",
    "Tomato___Target_Spot": "Tomato___Target_Spot",
    "Tomato___healthy": "Tomato___healthy",
    "Potato___Early_blight": "Potato___Early_blight",
    "Potato___Late_blight": "Potato___Late_blight",
    "Potato___healthy": "Potato___healthy",
    "Pepper,_bell___Bacterial_spot": "Pepper___Bacterial_spot",
    "Pepper,_bell___healthy": "Pepper___healthy",
}
BEANS_MAP = {
    "angular_leaf_spot": "Bean___Angular_leaf_spot",
    "bean_rust": "Bean___Bean_rust",
    "healthy": "Bean___healthy",
}
CASSAVA_MAP = {
    "cmd": "Cassava___Mosaic_disease",
    "cbsd": "Cassava___Brown_streak_disease",
    "cbb": "Cassava___Bacterial_blight",
    "cgm": "Cassava___Green_mite",
    "healthy": "Cassava___healthy",
}

IMG_SIZE = 224
BATCH_SIZE = 32
AUTOTUNE = tf.data.AUTOTUNE


def build_lut(source_names, name_map):
    """Return an int64 tensor: source_label_index -> canonical index (or -1)."""
    lut = []
    for name in source_names:
        target = name_map.get(name)
        lut.append(LABEL_TO_INDEX[target] if target is not None else -1)
    # Sanity: every mapping key must exist in the dataset's class names
    missing = set(name_map) - set(source_names)
    if missing:
        raise ValueError(f"mapping keys not found in dataset classes: {missing}")
    return tf.constant(lut, dtype=tf.int64)


def load_source(name, split, name_map, training):
    """Load a tfds source, remap to canonical indices, drop unused classes."""
    ds, info = tfds.load(name, split=split, with_info=True)
    source_names = info.features["label"].names
    lut = build_lut(source_names, name_map)

    def _map(example):
        img = tf.image.resize(example["image"], (IMG_SIZE, IMG_SIZE))
        img = tf.cast(img, tf.float32) / 255.0  # -> [0, 1], matches the app
        label = tf.gather(lut, example["label"])
        return img, label

    ds = ds.map(_map, num_parallel_calls=AUTOTUNE)
    ds = ds.filter(lambda _img, label: label >= 0)  # drop classes we don't use
    return ds


def augment(img, label):
    img = tf.image.random_flip_left_right(img)
    img = tf.image.random_brightness(img, 0.1)
    img = tf.image.random_contrast(img, 0.9, 1.1)
    img = tf.clip_by_value(img, 0.0, 1.0)
    return img, label


def count_class_frequencies():
    """Fast label-only pass (skips image decode) for class weighting."""
    counts = np.zeros(NUM_CLASSES, dtype=np.int64)
    for ds_name, split, name_map in [
        ("plant_village", "train", PLANT_VILLAGE_MAP),
        ("beans", "train+validation+test", BEANS_MAP),
        ("cassava", "train+validation+test", CASSAVA_MAP),
    ]:
        ds, info = tfds.load(
            ds_name, split=split, with_info=True,
            decoders={"image": tfds.decode.SkipDecoding()},
        )
        source_names = info.features["label"].names
        lut = [LABEL_TO_INDEX.get(name_map.get(n), -1) for n in source_names]
        for ex in tfds.as_numpy(ds):
            idx = lut[int(ex["label"])]
            if idx >= 0:
                counts[idx] += 1
    return counts


def build_dataset():
    parts = [
        load_source("plant_village", "train", PLANT_VILLAGE_MAP, training=True),
        load_source("beans", "train+validation+test", BEANS_MAP, training=True),
        load_source("cassava", "train+validation+test", CASSAVA_MAP, training=True),
    ]
    combined = parts[0]
    for p in parts[1:]:
        combined = combined.concatenate(p)

    # Deterministic shuffle so the train/val split below never overlaps
    combined = combined.shuffle(20000, seed=42, reshuffle_each_iteration=False)

    # 1-in-8 held out for validation
    val = combined.enumerate().filter(lambda i, _d: i % 8 == 0).map(lambda _i, d: d)
    train = combined.enumerate().filter(lambda i, _d: i % 8 != 0).map(lambda _i, d: d)

    train = (train.map(augment, num_parallel_calls=AUTOTUNE)
                  .batch(BATCH_SIZE).prefetch(AUTOTUNE))
    val = val.batch(BATCH_SIZE).prefetch(AUTOTUNE)
    return train, val


def build_model():
    inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))  # app feeds [0, 1]
    # MobileNetV2 was pretrained on [-1, 1]; remap inside the graph so the
    # deployed model keeps its [0, 1] input contract with the app.
    x = tf.keras.layers.Rescaling(scale=2.0, offset=-1.0)(inputs)
    base = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3), include_top=False, weights="imagenet"
    )
    base.trainable = False
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(NUM_CLASSES, activation="softmax")(x)
    model = tf.keras.Model(inputs, outputs)
    return model, base


def main():
    print("Counting class frequencies for class weights...")
    counts = count_class_frequencies()
    for name, c in zip(CANONICAL_LABELS, counts):
        print(f"  {name:40s} {c}")
    if (counts == 0).any():
        missing = [CANONICAL_LABELS[i] for i in np.where(counts == 0)[0]]
        raise RuntimeError(f"No samples found for classes: {missing}")
    total = counts.sum()
    class_weight = {i: total / (NUM_CLASSES * c) for i, c in enumerate(counts)}

    print("Building datasets...")
    train_ds, val_ds = build_dataset()

    model, base = build_model()
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    print("\nPhase 1: training classifier head (base frozen)...")
    model.fit(train_ds, validation_data=val_ds, epochs=5,
              class_weight=class_weight)

    print("\nPhase 2: fine-tuning top of MobileNetV2...")
    base.trainable = True
    for layer in base.layers[:-30]:  # unfreeze only the top ~30 layers
        layer.trainable = False
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(train_ds, validation_data=val_ds, epochs=5,
              class_weight=class_weight)

    print("\nExporting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]  # smaller; keeps float32 I/O
    tflite_model = converter.convert()

    out_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(out_dir, "plant_disease.tflite")
    labels_path = os.path.join(out_dir, "labels.txt")
    with open(model_path, "wb") as f:
        f.write(tflite_model)
    with open(labels_path, "w") as f:
        f.write("\n".join(CANONICAL_LABELS) + "\n")

    size_mb = os.path.getsize(model_path) / 1e6
    print(f"\nDone.\n  {model_path}  ({size_mb:.1f} MB)\n  {labels_path}")
    print("Copy both into mobile/assets/models/ and run `flutter run`.")


if __name__ == "__main__":
    main()
