# ShambaDoc

> AI-Powered Crop Disease Diagnosis for Kenyan Smallholder Farmers  
> Campus Spark Innovation Challenge 2026

## Project Structure

```
shambadoc/
├── mobile/                 # Flutter mobile application
│   ├── lib/
│   │   ├── app/            # Routes & theming
│   │   ├── ai/             # TFLite & Cloud AI services
│   │   ├── services/       # Storage, API, Auth
│   │   ├── features/       # Scan, History, Map, Settings
│   │   ├── widgets/        # Reusable UI components
│   │   └── l10n/           # English & Kiswahili localization
│   ├── assets/
│   │   ├── models/         # plant_disease.tflite + labels.txt
│   │   ├── images/
│   │   └── icons/
│   └── pubspec.yaml
│
├── backend/                # Node.js REST API
│   ├── src/
│   │   ├── middleware/     # Firebase & JWT auth
│   │   ├── routes/         # API endpoints
│   │   ├── controllers/    # Business logic
│   │   └── services/       # Plant.id & Google Maps
│   ├── database/
│   │   └── schema.sql      # PostgreSQL schema
│   ├── .env.example
│   └── package.json
│
└── docs/                   # Architecture & setup guides
```

## Full Software Blueprint

The implementation blueprint is captured in `docs/software_design.md`. It maps the enhanced product requirements into releases, mobile architecture, backend APIs, data model, AI flow, privacy controls, revenue features, and MVP acceptance criteria.

For deployment, follow `docs/go_live.md`. It covers Render backend deployment, PostgreSQL setup, environment variables, and Android release builds.

## Mobile App (Flutter)

### Prerequisites
- Flutter SDK >= 3.0.0
- Android Studio / Xcode
- Firebase project configured

### Setup
```bash
cd mobile
flutter pub get
```

### Add AI Model
Place your TensorFlow Lite model and labels in:
- `assets/models/plant_disease.tflite`
- `assets/models/labels.txt`

### Run
```bash
flutter run
```

### Features
- **Offline-first** TFLite disease detection (26 classes)
- **Cloud fallback** via Plant.id API when confidence < 75%
- **Bilingual** support (English / Kiswahili)
- **GPS tagging** for scan locations
- **Agro-dealer map** with nearest input suppliers
- **Firebase Phone Auth** for farmer identity
- **Local SQLite** history storage

## Backend API (Node.js)

### Prerequisites
- Node.js >= 18
- PostgreSQL >= 14
- Firebase Admin SDK credentials

### Setup
```bash
cd backend
cp .env.example .env
# Edit .env with your credentials
npm install
```

### Database
```bash
psql -U postgres -d shambadoc -f database/schema.sql
```

### Run
```bash
npm run dev   # Development
npm start     # Production
```

### API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | /health | None | Health check |
| POST | /api/diagnose/log | Optional | Log a scan |
| GET | /api/diagnose/heatmap | Firebase | Disease heatmap data |
| POST | /api/diagnose/feedback | Optional | Submit feedback |
| GET | /api/diagnose/stats | None | Regional statistics |
| GET | /api/dealers | None | Nearby agro-dealers |
| GET | /api/dealers/:id | None | Dealer details |
| POST | /api/dealers | Firebase | Register dealer |
| PUT | /api/dealers/:id | Firebase | Update dealer |

## Environment Variables

### Backend (.env)
```bash
PORT=3000
NODE_ENV=development

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shambadoc
DB_USER=postgres
DB_PASSWORD=your_password

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@yourproject.iam.gserviceaccount.com

# JWT
JWT_SECRET=your_super_secret_key
JWT_EXPIRES_IN=7d

# External APIs
PLANT_ID_API_KEY=your_plant_id_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

## Authors
- Nicholas Matata
- Willis Otieno

## License
MIT License — Campus Spark Innovation Challenge 2026
