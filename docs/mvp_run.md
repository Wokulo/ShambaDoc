# Running the ShambaDoc MVP

This guide gets the Flutter app building and running on an Android device/emulator.
It assumes the code prep in the repo is already done (broken deps removed, assets
scaffolded, Firebase made optional).

## 1. Install the Flutter SDK (one-time)

Flutter 3.44 / Dart 3.12 is installed on this machine and the Android platform
folder is committed, so steps 1–2 are already done. On a fresh machine:

- Windows install guide: https://docs.flutter.dev/get-started/install/windows
- Install Android Studio too (for the Android SDK + an emulator, or use a real
  phone with USB debugging enabled).

Verify:

```powershell
flutter --version
flutter doctor      # fix anything it flags, especially "Android toolchain"
```

## 2. Platform shells

`mobile/android/` is already in the repo. If you ever need the iOS/web shells,
`flutter create .` from `mobile/` fills in missing platform folders without touching
`lib/`.

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

### What works right now (no backend, no Firebase)

- Splash → Home → navigation to Scan / History / Settings / Map screens.
- The app launches even though Firebase is unconfigured (init is wrapped in
  try/catch).
- **Offline crop scanning** — the trained 18-class model is bundled in
  `assets/models/plant_disease.tflite`, so camera → diagnosis → treatment card
  works with no network.
- Scan history persisted locally via sqflite.

### What does NOT work yet (expected)

- **Agro-dealer map** → needs a Google Maps API key and a running backend.
- **Cloud fallback / scan logging** → needs the backend deployed and its URL passed
  via `--dart-define=SHAMBADOC_API_URL=...`.
- **Phone login** → needs Firebase configured (`flutterfire configure`).

## 5. The diagnosis model

Already trained and committed — nothing to do. `mobile/assets/models/plant_disease.tflite`
is a 2.5 MB dynamic-range-quantized MobileNetV2 covering **18 PlantVillage classes**
across maize, tomato, potato and pepper (the beans and cassava sources were dead, so
they are out of scope for this model).

Input contract: 224×224 RGB float32 in `[0, 1]`, shape `[1, 224, 224, 3]` → output
`[1, 18]`, matching `numClasses` in [`tflite_service.dart`](../mobile/lib/ai/tflite_service.dart#L17).

To retrain or add classes, use the Colab trainer in
[`mobile/model_training/`](../mobile/model_training/README.md) and see
[`mobile/assets/models/README.md`](../mobile/assets/models/README.md).

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
# output: build/app/outputs/flutter-apk/app-release.apk  (75.8 MB)
```

That universal APK bundles native libraries for all three ABIs. To hand out something
farmers can actually download over mobile data, split it:

```powershell
flutter build apk --release --split-per-abi
# app-arm64-v8a-release.apk    28.6 MB  <- give this one to most phones
# app-armeabi-v7a-release.apk  24.2 MB  <- older 32-bit devices
# app-x86_64-release.apk       31.8 MB  <- emulators only, don't distribute
```

See [`go_live.md`](go_live.md#5-android-build) for the full breakdown.
