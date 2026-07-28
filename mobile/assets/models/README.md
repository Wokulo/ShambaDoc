# AI Model Assets

This directory contains the on-device classifier that powers offline scanning.

## Files

| File | Status | Notes |
|------|--------|-------|
| `plant_disease.tflite` | Present (2.5 MB) | MobileNetV2, dynamic-range quantized, trained on 18 PlantVillage classes (maize, tomato, potato, pepper). |
| `labels.txt` | Present (18 lines) | One class per line, in the model's exact output order. |

Both are bundled via `pubspec.yaml` (`assets/models/`), so a release APK scans
offline with no backend and no Firebase.

## Model contract (see `lib/ai/tflite_service.dart`)

- **Input:** 224×224 RGB, float32, normalized to `[0, 1]`, shape `[1, 224, 224, 3]`.
- **Output:** shape `[1, N]` softmax probabilities, where `N` == number of lines in `labels.txt`.
- **Label format:** `Crop___Disease` (three underscores separate crop and disease;
  single underscores become spaces in the UI). A healthy class is `Crop___healthy`.
- `numClasses` in `tflite_service.dart` (currently 18) must equal `N`.

The bundled model uses **dynamic-range** quantization: weights are int8 but the
input/output tensors stay float32, so the `[0, 1]` preprocessing in
`tflite_service.dart` is correct as written. A **full-integer** quantized model would
have `uint8` input/output and would require changing that preprocessing.

Note the model's first layer rescales `[0, 1]` → `[-1, 1]` internally (MobileNetV2's
expected range), which is why the app only divides by 255.

## Retraining / extending the class list

1. Open [`../../model_training/ShambaDoc_train_colab.ipynb`](../../model_training/README.md)
   on Google Colab (free GPU) and run the cells.
2. It trains MobileNetV2 transfer-learning on PlantVillage and exports
   `plant_disease.tflite` + `labels.txt`.
3. Copy both files here, then update `numClasses` in `lib/ai/tflite_service.dart` if
   the class count changed.
