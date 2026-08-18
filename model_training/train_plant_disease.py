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

Runtime: ~45-90 min on a Colab T4 GPU (the heavier augmentation and longer
fine-tune cost more than the original ~15-30 min run). No TFDS needed.

The run ends by printing TWO accuracies -- a clean one and a deliberately
pessimistic "field-proxy" one. Read the note it prints: the clean number is
inflated by near-duplicate leakage in PlantVillage and neither number predicts
accuracy on real farmer photos.
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


def _random_rotate_and_zoom(img):
    """Random rotation (+/-25 deg) and 0.7-1.0x centre zoom, via crop+resize.

    tf.image has no rotation op, and pulling in tensorflow_addons just for one
    is not worth the dependency, so rotation is done with a rotation matrix
    through tf.raw_ops.ImageProjectiveTransformV3 (the op Keras' own
    RandomRotation layer uses underneath).
    """
    angle = tf.random.uniform([], -25.0, 25.0) * np.pi / 180.0
    cos_a, sin_a = tf.cos(angle), tf.sin(angle)
    centre = tf.cast(IMG_SIZE, tf.float32) / 2.0
    # Offsets keep the rotation about the image centre rather than the origin.
    x_off = centre - cos_a * centre + sin_a * centre
    y_off = centre - sin_a * centre - cos_a * centre
    transform = tf.stack(
        [cos_a, -sin_a, x_off, sin_a, cos_a, y_off, 0.0, 0.0]
    )[tf.newaxis, :]
    img = tf.raw_ops.ImageProjectiveTransformV3(
        images=img[tf.newaxis, ...],
        transforms=transform,
        output_shape=tf.constant([IMG_SIZE, IMG_SIZE], tf.int32),
        fill_value=0.0,
        interpolation="BILINEAR",
        fill_mode="REFLECT",
    )[0]

    # Random zoom: crop a 70-100% centre-ish window, then resize back up. This
    # is what varying phone-to-leaf distance actually looks like.
    scale = tf.random.uniform([], 0.7, 1.0)
    crop_size = tf.cast(tf.cast(IMG_SIZE, tf.float32) * scale, tf.int32)
    img = tf.image.random_crop(img, size=[crop_size, crop_size, 3])
    img = tf.image.resize(img, (IMG_SIZE, IMG_SIZE))
    return img


def augment(img, label):
    """Field-condition augmentation.

    The old version only flipped and nudged brightness/contrast by 10%, which
    teaches the model almost nothing about the conditions it actually fails in.
    PlantVillage is a lab dataset -- one plucked leaf, even lighting, plain
    background, always upright and centred -- so a model trained on it near
    memorises that setup. Farmers shoot leaves still on the plant, at an angle,
    in harsh sun or shade, from varying distance, with a cheap sensor.
    Everything below simulates one of those gaps.
    """
    img = tf.image.random_flip_left_right(img)
    img = tf.image.random_flip_up_down(img)
    img = _random_rotate_and_zoom(img)

    # Lighting: full sun to open shade is a far wider swing than +/-10%.
    img = tf.image.random_brightness(img, 0.30)
    img = tf.image.random_contrast(img, 0.6, 1.5)
    # Colour: white balance drifts hard between phones and between sun/shade.
    img = tf.image.random_saturation(img, 0.6, 1.5)
    img = tf.image.random_hue(img, 0.04)

    # Sensor noise + focus miss on a cheap camera.
    img = img + tf.random.normal(tf.shape(img), stddev=tf.random.uniform([], 0.0, 0.04))
    img = tf.clip_by_value(img, 0.0, 1.0)

    # JPEG artefacts: the app compresses before inference, the lab images did
    # not. Needs uint8 round-trip, so it is done last.
    img = tf.image.adjust_jpeg_quality(img, tf.random.uniform([], 40, 100, tf.int32))
    img = tf.clip_by_value(img, 0.0, 1.0)
    return img, label


def field_proxy_corrupt(img, label):
    """Fixed, deliberately harsh corruption used only for the field-proxy metric.

    Clean validation accuracy on PlantVillage is a near-meaningless number (see
    the note in main()), so this gives a second, pessimistic reading: the same
    held-out images pushed toward field conditions. It is a proxy, not a
    substitute for real farmer photos, but the gap between the two numbers is
    an honest measure of how brittle the model is off-distribution.

    Deterministic (fixed seed) so the metric is comparable across runs.
    """
    img = tf.image.adjust_brightness(img, 0.15)
    img = tf.image.adjust_contrast(img, 0.75)
    img = tf.image.adjust_saturation(img, 1.3)
    img = tf.image.central_crop(img, 0.8)
    img = tf.image.resize(img, (IMG_SIZE, IMG_SIZE))
    img = img + tf.random.stateless_normal(tf.shape(img), seed=[7, 7], stddev=0.03)
    img = tf.clip_by_value(img, 0.0, 1.0)
    img = tf.image.adjust_jpeg_quality(img, 55)
    return tf.clip_by_value(img, 0.0, 1.0), label


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
    # Same held-out images, pushed toward field conditions. Reported alongside
    # the clean number so the run ends with an honest pair, not one flattering
    # figure. See the accuracy note printed at the end of main().
    field_val = (tf.data.Dataset.from_tensor_slices((va_p, va_l))
                 .map(_decode, num_parallel_calls=AUTOTUNE)
                 .map(field_proxy_corrupt, num_parallel_calls=AUTOTUNE)
                 .batch(BATCH_SIZE).prefetch(AUTOTUNE))
    return train, val, field_val


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
    train_ds, val_ds, field_val_ds = build_dataset()

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
    # Unfreeze the top ~60 layers rather than ~30: with the much stronger
    # augmentation above, the earlier setup underfits -- it cannot adapt enough
    # of the feature extractor to cope with the added variation.
    for layer in base.layers[:-60]:
        layer.trainable = False
    # Keep every BatchNorm frozen. Fine-tuning BN on batches whose statistics
    # differ from ImageNet's wrecks the pretrained running means, and it is the
    # classic way a fine-tune scores well in training and badly at inference,
    # where BN switches to those corrupted running statistics.
    for layer in base.layers:
        if isinstance(layer, tf.keras.layers.BatchNormalization):
            layer.trainable = False
    model.compile(
        # 1e-5 across only 5 epochs barely moved the weights. 5e-5 with more
        # epochs and early stopping actually lets the fine-tune converge under
        # the heavier augmentation, without cooking the pretrained features.
        optimizer=tf.keras.optimizers.Adam(5e-5),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.fit(
        train_ds, validation_data=val_ds, epochs=15, class_weight=class_weight,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy", patience=3, restore_best_weights=True
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss", factor=0.3, patience=2, min_lr=1e-6
            ),
        ],
    )

    # ---------------------------------------------------------------------
    # Honest evaluation
    # ---------------------------------------------------------------------
    print("\nEvaluating...")
    clean_loss, clean_acc = model.evaluate(val_ds, verbose=0)
    field_loss, field_acc = model.evaluate(field_val_ds, verbose=0)
    print(f"  clean val accuracy       : {clean_acc:.4f}")
    print(f"  field-proxy val accuracy : {field_acc:.4f}")
    print(
        "\nREAD THIS BEFORE TRUSTING THE NUMBER ABOVE\n"
        "  The clean figure is optimistic and always has been. PlantVillage\n"
        "  holds many near-duplicate shots of the SAME physical leaf, and the\n"
        "  split here is random, so near-duplicates of a leaf land in both\n"
        "  train and validation. That measures memorisation as much as skill.\n"
        "  The field-proxy figure re-scores the same held-out images under\n"
        "  harsher light, colour, crop, noise and JPEG settings; the gap\n"
        "  between the two is how brittle the model is off-distribution.\n"
        "  Neither number predicts accuracy on real farmer photos. Only a\n"
        "  test set of real field images can do that -- collect one during the\n"
        "  pilot and evaluate against it before claiming any accuracy figure."
    )

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
