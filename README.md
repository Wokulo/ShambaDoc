# ShambaDoc

> AI-Powered Connected Agriculture Ecosystem Platform for Kenyan Smallholder Farmers  
> Campus Spark Innovation Challenge 2026

## Project Structure

```
shambadoc/
├── lib/                        # Flutter mobile application
│   ├── app/                    # Routes & theming
│   ├── ai/                     # Cloud AI & prediction services
│   ├── models/                 # Data models
│   ├── services/               # Storage, API client, Auth
│   ├── features/               # Scan, History, Map, Settings, Providers
│   └── widgets/                # Reusable UI components
│
├── backend/                    # Node.js REST API
│   ├── src/
│   │   ├── middleware/         # Firebase & JWT auth
│   │   ├── routes/             # API endpoints
│   │   ├── controllers/        # Business logic
│   │   └── services/           # Plant.id & Google Maps
│   ├── database/
│   │   └── schema.sql          # PostgreSQL schema
│   ├── .env.example
│   └── package.json
│
└── docs/                       # Architecture & setup guides
```

## Features

- **AI crop disease analysis** — Cloud AI with confidence scoring
- **Farmer profiles** — Firebase-authenticated farmer accounts
- **Disease cases** — Track and manage crop health issues
- **Agronomist discovery** — Find nearby agricultural experts
- **Government services** — County agricultural officers and advisories
- **Agrovets** — Input supplier discovery and inquiries
- **SACCOs** — Financial service discovery
- **Agricultural insurance** — Provider discovery and inquiries
- **Consultations** — Chat with agronomists and officers
- **Notifications** — Real-time updates
- **Location-based discovery** — GPS-tagged services

## Technology

- **Frontend:** Flutter
- **Backend:** Node.js / Express
- **Database:** PostgreSQL
- **Authentication:** Firebase Authentication (Phone)
- **AI:** Cloud AI API with development fallback

## Mobile App (Flutter)

### Prerequisites
- Flutter SDK >= 3.0.0
- Android Studio / Xcode
- Firebase project configured

### Setup
```bash
flutter pub get
```

### AI Model Requirement

**Local TFLite model is NOT currently bundled.**

The application requires `assets/models/plant_disease.tflite` for on-device AI inference. This model must be supplied before production deployment.

Until the local model is available, the app uses:
1. **Cloud AI API** (`https://shambadoc-api.onrender.com/predict`) — primary
2. **Plant.id** — secondary fallback (requires `PLANT_ID_API_KEY`)
3. **Development fallback** — returns `AI_UNAVAILABLE` status; never shown as a real diagnosis

If no real AI result is available, the UI clearly states:
> "Diagnosis unavailable — We could not obtain a reliable AI diagnosis at this time."

### Run
```bash
flutter run
# or with custom API URL
flutter run --dart-define=SHAMBADOC_API_URL=https://your-api.example.com/api
```

### Build
```bash
flutter build apk --debug   # Debug build
flutter build apk --release # Release build
```

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

### Environment Variables

#### Backend (.env)
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

#### Flutter (--dart-define)
```bash
# API base URL
SHAMBADOC_API_URL=https://your-api.example.com/api

# Plant.id API key (optional cloud fallback)
PLANT_ID_API_KEY=your_plant_id_key
```

## Security

- All protected endpoints require Firebase ID token via `Authorization: Bearer <token>`
- Backend verifies tokens using `verifyFirebaseToken` middleware
- Farmer data is scoped by authenticated `req.user.uid`
- No tokens are stored in SharedPreferences or plain local storage
- No client-supplied user IDs are trusted for protected routes

## Authors
- Nicholas Matata
- Willis Otieno

## License
MIT License — Campus Spark Innovation Challenge 2026
