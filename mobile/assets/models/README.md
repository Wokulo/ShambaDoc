# AI Model Assets

This directory must contain the on-device classifier before the scan feature works.

## Required files

| File | Status | Notes |
|------|--------|-------|
| `plant_disease.tflite` | **MISSING — you must add this** | The TensorFlow Lite crop-disease classifier. |
| `labels.txt` | Placeholder present | One class per line. **Must match the model's output order exactly.** |

Until `plant_disease.tflite` exists, `TFLiteService.init()` throws and a scan shows
"Failed to analyze image" — the rest of the app still runs.

## Model contract (see `lib/ai/tflite_service.dart`)

- **Input:** 224×224 RGB, float32, normalized to `[0, 1]`, shape `[1, 224, 224, 3]`.
- **Output:** shape `[1, N]` softmax probabilities, where `N` == number of lines in `labels.txt`.
- **Label format:** `Crop___Disease` (three underscores separate crop and disease;
  single underscores become spaces in the UI). A healthy class is `Crop___healthy`.
- `numClasses` in `tflite_service.dart` (currently 18) must equal `N`.

If you train a **quantized** model, the input/output are `uint8` and the preprocessing
in `tflite_service.dart` must change — it currently assumes float32.

## Fastest path to a real model

1. Train MobileNetV2 transfer-learning on the PlantVillage dataset (or a Kenya-specific
   crop set), constrained to the crops/classes in `labels.txt`.
2. Export to TFLite: `converter = tf.lite.TFLiteConverter.from_keras_model(model)`.
3. Save the exported model here as `plant_disease.tflite` and overwrite `labels.txt`
   with the exact class order used during training.
