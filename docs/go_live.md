# ShambaDoc Go-Live Guide

This guide takes ShambaDoc from local code to a public backend API and a production-ready mobile build.

## 1. What Goes Live First

Launch in this order:

1. PostgreSQL database.
2. Node.js backend API.
3. Firebase project and mobile app credentials.
4. Android test build for farmers and judges.
5. Optional custom domain and landing page.

The backend is the first live component because the mobile app needs it for scan logging, feedback, dealers, heatmaps, and future payments.

## 2. Backend Deployment

Recommended simple path: Render.

1. Push this repository to GitHub.
2. Create a new Render Blueprint from `render.yaml`.
3. Render will create:
   - `shambadoc-api`
   - `shambadoc-postgres`
4. Add these secret environment variables in Render:
   - `CORS_ORIGINS`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_PRIVATE_KEY_ID`
   - `FIREBASE_PRIVATE_KEY`
   - `FIREBASE_CLIENT_EMAIL`
   - `PLANT_ID_API_KEY`
   - `GOOGLE_MAPS_API_KEY`
5. Deploy the service.
6. Open `https://<your-render-service>.onrender.com/health`.

Expected response:

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

## 3. Database Setup

After the PostgreSQL database exists, run the schema:

```bash
psql "$DATABASE_URL" -f backend/database/schema.sql
```

If your host gives separate values instead of `DATABASE_URL`, use:

```bash
psql -h <host> -p <port> -U <user> -d <database> -f backend/database/schema.sql
```

## 4. Production Environment Variables

Backend:

```bash
NODE_ENV=production
PORT=3000
CORS_ORIGINS=https://shambadoc.app,https://www.shambadoc.app
DB_HOST=<postgres-host>
DB_PORT=5432
DB_NAME=<postgres-db>
DB_USER=<postgres-user>
DB_PASSWORD=<postgres-password>
DB_SSL=true
# Or DATABASE_URL=<postgres-connection-string>
FIREBASE_PROJECT_ID=<firebase-project-id>
FIREBASE_PRIVATE_KEY_ID=<firebase-private-key-id>
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=<firebase-client-email>
JWT_SECRET=<long-random-secret>
JWT_EXPIRES_IN=7d
PLANT_ID_API_KEY=<plant-id-key>
GOOGLE_MAPS_API_KEY=<google-maps-key>
```

Mobile build-time values:

```bash
--dart-define=SHAMBADOC_API_URL=https://<your-backend-domain>/api
--dart-define=PLANT_ID_API_KEY=<plant-id-key>
```

## 5. Android Build

From the `mobile` folder:

```bash
flutter pub get
flutter build apk --release --dart-define=SHAMBADOC_API_URL=https://<your-backend-domain>/api --dart-define=PLANT_ID_API_KEY=<plant-id-key>
```

### Use `--split-per-abi` for sideloaded pilot APKs

A universal APK is **75.8 MB** because it carries three copies of the native libraries
(Flutter engine + TFLite runtime), including an `x86_64` slice that only Android
emulators use. Adding `--split-per-abi` produces one APK per architecture:

| Artifact | Size | Who needs it |
|----------|------|--------------|
| `app-arm64-v8a-release.apk` | 28.6 MB | Almost every phone from ~2016 onward |
| `app-armeabi-v7a-release.apk` | 24.2 MB | Older / entry-level 32-bit devices |
| `app-x86_64-release.apk` | 31.8 MB | Emulators only — do not distribute |
| `app-release.apk` (universal) | 75.8 MB | Fallback if you can't tell which device |

```bash
flutter build apk --release --split-per-abi --dart-define=SHAMBADOC_API_URL=https://<your-backend-domain>/api --dart-define=PLANT_ID_API_KEY=<plant-id-key>
```

This matters for the pilot: farmers download over mobile data, so shipping the arm64
APK cuts the download by roughly two-thirds. Google Play handles this automatically
via the app bundle, so the split only applies to APKs you distribute yourself.

For Google Play:

```bash
flutter build appbundle --release --dart-define=SHAMBADOC_API_URL=https://<your-backend-domain>/api --dart-define=PLANT_ID_API_KEY=<plant-id-key>
```

Before a public Play Store release, configure Android signing keys and confirm Firebase Android app settings.

## 6. Launch Checks

Backend:

- `/health` returns `status: ok`.
- `/api/dealers?lat=-0.1022&lng=34.7617` returns dealers.
- `/api/diagnose/log` accepts a test scan.
- `/api/diagnose/feedback` accepts feedback.
- Database schema has been applied.
- Production CORS allows only your real domains.

Mobile:

- App installs on a real Android device.
- Camera permission works.
- Offline scan still reaches a result.
- Low confidence result shows retake guidance.
- Scan history persists after app restart.
- Dealer map opens.
- Backend URL is not the placeholder.

## 7. Current Blockers To Resolve Before Public Launch

Already done:

- ~~Install Flutter/Dart on the build machine~~ — Flutter 3.44 / Dart 3.12 installed, release APK builds.
- ~~Add real TFLite model and labels in `mobile/assets/models/`~~ — 18-class MobileNetV2 bundled; offline scanning works.

Still outstanding:

- Configure Firebase Android app files.
- Add Google Maps API key to Android native configuration.
- Set production backend secrets in the hosting provider.
- Apply `backend/database/schema.sql` to production PostgreSQL.

## 8. Suggested First Public Release

Ship a pilot APK first, not a full public Play Store release. Give it to 20-50 farmers, SACCO members, or judges. Capture:

- Number of scans.
- Most common crops.
- Most common disease predictions.
- Confidence distribution.
- Treatment feedback.
- Dealer contact taps.

Use those metrics before moving to a broader release.
