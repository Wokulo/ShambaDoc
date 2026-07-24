# Running the ShambaDoc MVP

This guide gets the Flutter app building and running on an Android device/emulator.
It assumes the code prep in the repo is already done (broken deps removed, assets
scaffolded, Firebase made optional).

## 1. Install the Flutter SDK (one-time)

Flutter is **not** installed on this machine yet — this is the current blocker.

- Windows install guide: https://docs.flutter.dev/get-started/install/windows
- Install Android Studio too (for the Android SDK + an emulator, or use a real
  phone with USB debugging enabled).

Verify:

```powershell
flutter --version
flutter doctor      # fix anything it flags, especially "Android toolchain"
```

## 2. Generate the platform shells

The repo only contains `lib/` + `pubspec.yaml` — there are no `android/` / `ios/`
folders, so the project cannot build yet. Generate them in place:

```powershell
cd mobile
flutter create .
```

`flutter create .` fills in the missing platform folders without touching your
existing `lib/` code.

## 3. Get dependencies

```powershell
flutter pub get
```

If this fails on a version conflict, run `flutter pub upgrade --major-versions`
and re-check. (The known-broken `tflite_flutter_helper` package has already been
removed from `pubspec.yaml`.)

## 4. Run it

```powershell
flutter run
```

### What works right now (no model, no backend, no Firebase)

- Splash → Home → navigation to Scan / History / Settings / Map screens.
- The app launches even though Firebase is unconfigured (init is wrapped in
  try/catch).

### What does NOT work yet (expected)

- **Scanning a crop** → shows "Failed to analyze image" because
  `assets/models/plant_disease.tflite` does not exist yet. See
  `mobile/assets/models/README.md` for the model contract and how to produce one.
- **Agro-dealer map** → needs a Google Maps API key and a running backend.
- **Cloud fallback / scan logging** → needs the backend deployed and its URL passed
  via `--dart-define=SHAMBADOC_API_URL=...`.
- **Phone login** → needs Firebase configured (`flutterfire configure`).

## 5. Add the model to unlock diagnosis

This is the single step that turns the app from a clickable shell into a working
diagnosis tool. A ready-to-run trainer is in
[`mobile/model_training/`](../mobile/model_training/README.md): open it on Google
Colab (free GPU), run three cells, and it trains MobileNetV2 on the PlantVillage +
beans + cassava datasets and exports `plant_disease.tflite` + `labels.txt` for all
26 classes. Drop both into `mobile/assets/models/`, then `flutter run` again.

Input contract: 224×224 RGB float32 in [0,1], output size 26 (== label count).

## 6. (Optional) Wire the backend later

Only after the offline loop works:

1. Backend bugs are already fixed (dealer `HAVING`→subquery, `auth.js` private-key
   regex, `diagnoseController` now populates `region`, plus the `scans` table gained
   the missing `confidence_tier`/`severity` columns and Firebase init is now
   optional so the API boots without credentials). Nothing to do here — just deploy.
2. Deploy per `docs/go_live.md`.
3. Run the app pointing at it:
   ```powershell
   flutter run --dart-define=SHAMBADOC_API_URL=https://your-api.onrender.com/api
   ```

## Build a release APK (for sharing a demo)

```powershell
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```
