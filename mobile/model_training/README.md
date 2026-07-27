# Training the ShambaDoc crop-disease model

This produces the `plant_disease.tflite` + `labels.txt` that the Flutter app
loads in [`mobile/lib/ai/tflite_service.dart`](../lib/ai/tflite_service.dart).
Without these files, every scan fails with *"Failed to analyze image."*

The model is **26 classes** across three public datasets, all pulled
automatically via TensorFlow Datasets — **no Kaggle account or manual downloads**:

| Crop    | Source dataset (tfds) | Classes |
|---------|-----------------------|---------|
| Maize, Tomato, Potato, Pepper | `plant_village` | 18 |
| Bean    | `beans`   | 3 |
| Cassava | `cassava` | 5 |

## Run it on Google Colab (recommended — free GPU)

### Easiest: the ready-made notebook

`ShambaDoc_train_colab.ipynb` (in this folder) is fully self-contained — it
embeds the trainer, so there is no `git clone` and nothing to keep in sync.

1. Go to <https://colab.research.google.com> → **File → Upload notebook** →
   pick `ShambaDoc_train_colab.ipynb`.
2. **Runtime → Change runtime type → T4 GPU → Save.**
3. **Runtime → Run all.** After ~20–40 min the last cell downloads
   `plant_disease.tflite` + `labels.txt` to your computer.

### Alternative: clone the repo

Only works once the latest trainer is pushed to the default branch. Paste and
run top to bottom:

```python
# Cell 1 — get the training script
!git clone https://github.com/Wokulo/ShambaDoc.git
%cd ShambaDoc/mobile/model_training
!pip -q install tensorflow_datasets
```

```python
# Cell 2 — train + export (≈20–40 min on a T4)
!python train_plant_disease.py
```

```python
# Cell 3 — download the two files to your computer
from google.colab import files
files.download("plant_disease.tflite")
files.download("labels.txt")
```

Then move both downloaded files into:

```
mobile/assets/models/plant_disease.tflite
mobile/assets/models/labels.txt      # overwrites the existing one (same 26 labels)
```

5. Back in the app: `cd mobile && flutter run`. Scanning now works offline.

## The input/output contract (don't break this)

The app and the model must agree exactly:

- **Input:** float32 `[1, 224, 224, 3]`, RGB, pixel values scaled to `[0, 1]`
  (the app divides by 255 before calling the interpreter).
- **Output:** float32 `[1, 26]` softmax scores. `argmax` → the line at that
  index in `labels.txt`.
- **Label order is load-bearing.** The script writes `labels.txt` in the same
  fixed order it trains against (`CANONICAL_LABELS` in the script), so the
  argmax index always maps to the right disease. If you edit the class list,
  regenerate **both** files together.

## Notes

- Uses MobileNetV2 transfer learning (ImageNet weights), two-phase: train the
  head with the base frozen, then fine-tune the top ~30 layers.
- Class imbalance is handled with per-class `class_weight`.
- Export uses dynamic-range quantization (`Optimize.DEFAULT`) — smaller file,
  float32 input/output preserved so `tflite_flutter` stays happy. On current
  Colab (TF ≥ 2.16 / Keras 3) it converts via an exported SavedModel, since
  `from_keras_model` is unreliable there; it falls back to `from_keras_model`
  on Keras 2. After export it loads the `.tflite` back and asserts the
  `float32 [1,224,224,3] → [1,26]` contract before finishing.
- This is trained on lab/greenhouse imagery (esp. PlantVillage). Accuracy on
  real Kenyan field photos will be lower — good enough for a demo/pilot, not a
  substitute for a field-collected dataset before wide release.
```
