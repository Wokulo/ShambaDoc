"""
ShambaDoc — Crop Disease Model Trainer
======================================

Trains a MobileNetV2 transfer-learning classifier and exports
`plant_disease.tflite` + `labels.txt` for the Flutter app.

The 18 target classes (maize, tomato, potato, pepper) come from PlantVillage,
read from a clone of the spMohanty mirror — the TFDS PlantVillage source is a
dead Mendeley URL (HTTP 403). Clone it first (in the dir you run this from):

    git clone --depth 1 https://github.com/spMohanty/PlantVillage-Dataset.git

(Beans + cassava were dropped: their datasets' hosting is dead/gated. They can
be re-added later from a reliable source; keep CANONICAL_LABELS and the app's
labels.txt / numClasses in sync if you do.)

CRITICAL CONTRACT with the app (mobile/lib/ai/tflite_service.dart):
  * Input : float32 [1, 224, 224, 3], RGB, values in [0, 1]
            (the app divides each pixel by 255 before inference)
  * Output: float32 [1, 18], softmax scores; argmax index -> labels.txt line
  * labels.txt line order MUST equal CANONICAL_LABELS below, or every
    prediction is mislabeled.

Run on Google Colab (free GPU):
  !git clone --depth 1 https://github.com/spMohanty/PlantVillage-Dataset.git
  !python train_plant_disease.py
Then download `plant_disease.tflite` + `labels.txt` and drop them into
  mobile/assets/models/

Runtime: ~15-30 min on a Colab T4 GPU. No TensorFlow Datasets needed.
"""

import os
import random
import numpy as np
import tensorflow as tf

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
    "Pepper___Bacterial_spot",
    "Pepper___healthy",
]
NUM_CLASSES = len(CANONICAL_LABELS)
assert NUM_CLASSES == 18, f"expected 18 classes, got {NUM_CLASSES}"
LABEL_TO_INDEX = {name: i for i, name in enumerate(CANONICAL_LABELS)}

# ---------------------------------------------------------------------------
# 2. PlantVillage source-folder -> canonical-label mapping (matched by folder
#    name, so it is robust to how the images are ordered on disk)
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
assert len(PLANT_VILLAGE_MAP) == NUM_CLASSES, "map size must equal class count"

IMG_SIZE = 224
BATCH_SIZE = 32
AUTOTUNE = tf.data.AUTOTUNE

# PlantVillage's TFDS source (a Mendeley URL) now returns HTTP 403, so we read it
# from a clone of the spMohanty mirror instead. Its raw/color folder names match
# the PLANT_VILLAGE_MAP keys exactly. Clone it before running, e.g.:
#   git clone --depth 1 https://github.com/spMohanty/PlantVillage-Dataset.git
PLANT_VILLAGE_DIR = os.environ.get(
    "PLANT_VILLAGE_DIR", "PlantVillage-Dataset/raw/color"
)


def augment(img, label):
    img = tf.image.random_flip_left_right(img)
    img = tf.image.random_brightness(img, 0.1)
    img = tf.image.random_contrast(img, 0.9, 1.1)
    img = tf.clip_by_value(img, 0.0, 1.0)
    return img, label


def list_plant_village_files(name_map):
    """(filepaths, canonical_indices) for the mapped PlantVillage color folders."""
    paths, labels = [], []
    for src_name, canonical in name_map.items():
        folder = os.path.join(PLANT_VILLAGE_DIR, src_name)
        if not os.path.isdir(folder):
            raise FileNotFoundError(
                f"PlantVillage folder not found: {folder}\n"
                f"Clone the mirror first (in the same dir you run this from):\n"
                f"  git clone --depth 1 "
                f"https://github.com/spMohanty/PlantVillage-Dataset.git\n"
                f"or set PLANT_VILLAGE_DIR to its raw/color path."
            )
        idx = LABEL_TO_INDEX[canonical]
        for fn in os.listdir(folder):
            if fn.lower().endswith((".jpg", ".jpeg")):
                paths.append(os.path.join(folder, fn))
                labels.append(idx)
    # Files are grouped by class; interleave them so the downstream val split
    # (a bounded shuffle buffer + i % 8) sees every class.
    order = list(range(len(paths)))
    random.Random(42).shuffle(order)
    paths = [paths[i] for i in order]
    labels = [labels[i] for i in order]
    return paths, labels


def _decode(path, label):
    img = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
    img = tf.image.resize(img, (IMG_SIZE, IMG_SIZE))
    img = tf.cast(img, tf.float32) / 255.0  # -> [0, 1], matches the app
    return img, tf.cast(label, tf.int64)


def count_class_frequencies():
    """Count images per class from the cloned color folders (for class weights)."""
    counts = np.zeros(NUM_CLASSES, dtype=np.int64)
    for src_name, canonical in PLANT_VILLAGE_MAP.items():
        folder = os.path.join(PLANT_VILLAGE_DIR, src_name)
        if os.path.isdir(folder):  # a missing folder -> 0 count, caught in main()
            counts[LABEL_TO_INDEX[canonical]] += sum(
                1 for fn in os.listdir(folder)
                if fn.lower().endswith((".jpg", ".jpeg"))
            )
    return counts


def build_dataset():
    # The file list is already globally pre-shuffled (seed 42), so we split on
    # indices (1-in-8 held out for validation) and shuffle the lightweight
    # (path, label) pairs BEFORE decoding. Shuffling strings fills the buffer
    # instantly; a big shuffle buffer over decoded images instead stalls for
    # minutes at "Filling up shuffle buffer" and looks like a hang.
    paths, labels = list_plant_village_files(PLANT_VILLAGE_MAP)
    tr_p, tr_l, va_p, va_l = [], [], [], []
    for i, (p, lbl) in enumerate(zip(paths, labels)):
        if i % 8 == 0:
            va_p.append(p); va_l.append(lbl)
        else:
            tr_p.append(p); tr_l.append(lbl)

    train = (tf.data.Dataset.from_tensor_slices((tr_p, tr_l))
             .shuffle(len(tr_p), seed=42, reshuffle_each_iteration=True)
             .map(_decode, num_parallel_calls=AUTOTUNE)
             .map(augment, num_parallel_calls=AUTOTUNE)
             .batch(BATCH_SIZE).prefetch(AUTOTUNE))
    val = (tf.data.Dataset.from_tensor_slices((va_p, va_l))
           .map(_decode, num_parallel_calls=AUTOTUNE)
           .batch(BATCH_SIZE).prefetch(AUTOTUNE))
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
    out_dir = os.path.dirname(os.path.abspath(__file__))
    model_path = os.path.join(out_dir, "plant_disease.tflite")
    labels_path = os.path.join(out_dir, "labels.txt")

    # Current Colab ships TF >= 2.16 with Keras 3, where
    # TFLiteConverter.from_keras_model is unreliable for functional models.
    # Route through an exported SavedModel when available (Keras 3), and fall
    # back to the direct converter on Keras 2.
    if hasattr(model, "export"):
        saved_dir = os.path.join(out_dir, "saved_model")
        model.export(saved_dir)
        converter = tf.lite.TFLiteConverter.from_saved_model(saved_dir)
    else:
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]  # smaller; keeps float32 I/O
    tflite_model = converter.convert()

    with open(model_path, "wb") as f:
        f.write(tflite_model)
    with open(labels_path, "w") as f:
        f.write("\n".join(CANONICAL_LABELS) + "\n")

    # Verify the export matches the app's contract before you copy it over —
    # a shape/dtype drift here means every scan is silently mislabeled.
    interp = tf.lite.Interpreter(model_path=model_path)
    interp.allocate_tensors()
    in_det = interp.get_input_details()[0]
    out_det = interp.get_output_details()[0]
    print(f"  input : {np.dtype(in_det['dtype']).name} {list(in_det['shape'])}")
    print(f"  output: {np.dtype(out_det['dtype']).name} {list(out_det['shape'])}")
    assert list(in_det["shape"])[-3:] == [IMG_SIZE, IMG_SIZE, 3], "input != [*,224,224,3]"
    assert list(out_det["shape"])[-1] == NUM_CLASSES, f"output != [*,{NUM_CLASSES}]"
    assert in_det["dtype"] == np.float32, "input must be float32 (app feeds [0,1] float32)"
    assert out_det["dtype"] == np.float32, "output must be float32 softmax"

    size_mb = os.path.getsize(model_path) / 1e6
    print(f"\nDone.\n  {model_path}  ({size_mb:.1f} MB)\n  {labels_path}")
    print(f"Contract OK: float32 [1,{IMG_SIZE},{IMG_SIZE},3] -> [1,{NUM_CLASSES}].")
    print("Copy both into mobile/assets/models/ and run `flutter run`.")


if __name__ == "__main__":
    main()
