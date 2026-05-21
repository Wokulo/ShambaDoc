# ShambaDoc Full Software Design

Version: 1.0  
Date: May 2026  
Scope: Flutter mobile app, Node.js API, PostgreSQL data layer, AI services, and rollout roadmap.

## Product Goal

ShambaDoc helps Kenyan smallholder farmers diagnose crop disease quickly, offline first, and in plain English or Kiswahili. The first release must prove the core promise during a live demo: take a crop photo with internet disabled, run on-device AI, show a confidence-aware diagnosis, provide treatment guidance, save the scan, and guide the farmer to a nearby agro-dealer.

## Primary Users

- Farmer: scans crops, receives diagnosis and treatment, tracks crop history by plot, and finds input suppliers.
- Agro-dealer: appears in dealer listings, receives WhatsApp or phone leads for recommended treatments, and can pay for sponsored placement.
- SACCO or cooperative manager: supports farmer onboarding and group subscriptions.
- County or NGO analyst: views aggregated disease trends and outbreak heatmaps.
- Agronomist or admin: reviews uncertain cases, feedback, and field-photo training data.

## Release Strategy

### MVP Demo Release

- Offline camera scan with TFLite inference.
- Confidence-aware result states.
- Treatment card with dosage and safety guidance.
- Local scan history.
- GPS tag where permission is granted.
- Nearby agro-dealer map with sponsored dealer priority.
- Feedback prompt after diagnosis.
- Backend logging for scans, feedback, heatmap, stats, and dealers.

### Pilot Release

- Crop diary using named farm plots.
- Follow-up reminders at 7 and 14 days.
- Treatment outcome tracking.
- WhatsApp dealer lead flow.
- Admin-ready data model for sponsored dealer listings.
- Disease severity badge: early, moderate, severe.
- Swahili-first content pass for common farmer workflows.

### Revenue Release

- M-Pesa subscription support.
- Free scan quota and premium entitlements.
- SACCO group subscription accounts.
- County and NGO disease heatmap dashboard API.
- Weather-driven disease risk alerts.
- Dealer lead analytics and sponsored placement reporting.

### Scale Release

- Kenyan field-photo fine tuning.
- More crops and diseases.
- Human agronomist escalation queue.
- USSD symptom triage for feature phones.
- Federated learning design for privacy-preserving model improvement.

## Mobile Architecture

The Flutter app should remain offline-first. Local actions must work without the backend unless a feature explicitly requires internet.

- `features/scan`: camera capture, image validation, inference orchestration, result routing.
- `ai`: TFLite model runner, cloud fallback client, disease metadata.
- `features/history`: scan history and crop diary.
- `features/map`: agro-dealer map, sponsored dealer priority, call and WhatsApp actions.
- `features/settings`: language, offline mode, profile, consent, and data sync preferences.
- `services`: API client, storage, auth, notifications, subscriptions.
- `l10n`: English and Kiswahili strings.

## Scan Flow

1. Farmer opens scan screen.
2. App requests camera permission.
3. Farmer captures affected crop image.
4. App gets GPS location if permission is available.
5. TFLite model returns class and confidence.
6. App applies confidence state:
   - High confidence: `>= 0.75`; show diagnosis normally.
   - Uncertain: `0.40-0.74`; show diagnosis plus retake guidance and optional cloud check.
   - Low confidence: `< 0.40`; prompt retake, cloud escalation, or agronomist contact.
7. App derives severity from model output or visual proxy where available.
8. App saves scan locally immediately.
9. If online, app logs scan to backend asynchronously.
10. Result screen shows disease, confidence, severity, treatment, dosage, dealer action, and feedback.

## Backend Architecture

The backend is an Express REST API backed by PostgreSQL. It should accept mobile sync events, aggregate disease intelligence, serve dealer data, and support revenue features.

Current API surface:

- `GET /health`
- `POST /api/diagnose/log`
- `POST /api/diagnose/feedback`
- `GET /api/diagnose/heatmap`
- `GET /api/diagnose/stats`
- `GET /api/dealers`
- `GET /api/dealers/:id`
- `POST /api/dealers`
- `PUT /api/dealers/:id`

Planned API surface:

- `GET /api/diseases`: disease and treatment knowledge base.
- `POST /api/plots`: create farmer plot.
- `GET /api/plots`: list farmer plots.
- `POST /api/reminders`: create treatment follow-up reminder.
- `PUT /api/reminders/:id/outcome`: record recovery outcome.
- `POST /api/dealer-leads`: record call, WhatsApp, or map lead.
- `GET /api/weather/risk`: county-level disease risk based on weather.
- `POST /api/subscriptions/mpesa/stk-push`: start farmer payment.
- `POST /api/subscriptions/mpesa/callback`: receive M-Pesa callback.
- `GET /api/admin/escalations`: uncertain cases for agronomist review.
- `GET /api/admin/dashboard/stats`: B2B dashboard summary.

## Data Model

- `users`: Firebase-authenticated farmer, dealer, SACCO, admin, or analyst.
- `plots`: farmer field records for crop diary.
- `scans`: diagnosis events with location, confidence, severity, and sync metadata.
- `feedback`: diagnosis correctness and treatment outcome feedback.
- `follow_up_reminders`: 7-day and 14-day check-ins.
- `agro_dealers`: supplier profile, verification, sponsorship, product categories.
- `dealer_leads`: conversion events generated by map, phone, or WhatsApp actions.
- `subscriptions`: farmer, SACCO, dealer, and B2B plans.
- `mpesa_payments`: payment attempts and callback results.
- `weather_risk_alerts`: geo-targeted disease risk alerts.
- `disease_knowledge`: offline-cacheable disease and treatment content.
- `human_escalations`: low-confidence cases for agronomist review.

## AI Design

The on-device model is the default path. It must be small enough for mid-range Android phones and fast enough for a live offline demo.

Targets:

- Model size: less than 25 MB.
- Inference latency: less than 500 ms on mid-range Android.
- Accuracy target: greater than 88 percent on held-out PlantVillage test data.
- Confidence threshold for normal results: 75 percent.

Cloud fallback should run only when network is available, the user has consented where needed, local confidence is below threshold, and the image can be compressed safely. Cloud results should not silently override the offline result unless confidence is meaningfully better.

## Security And Privacy

- Firebase Auth verifies user identity.
- Farmer scans remain local unless sync is enabled or the scan is logged anonymously.
- B2B dashboards should avoid exposing identifiable farmer records.
- Admin routes require role checks.
- M-Pesa callbacks must validate provider metadata and idempotency.
- API requests should be rate limited and validated with Joi.
- Image upload should enforce size and content-type limits.

## Revenue Features

- Sponsored dealer listings: sponsored dealers sort first when relevant and are labeled clearly.
- Dealer analytics: map impressions, phone taps, WhatsApp taps, and product-specific leads.
- Farmer freemium: 10 free scans per month, then KES 200 monthly premium.
- SACCO subscriptions: group account with member entitlements.
- B2B dashboard: aggregate disease trends for counties, NGOs, and research users.

## Build Priorities

1. Make the offline demo flow polished and reliable.
2. Add confidence-aware UX and severity badges.
3. Add crop diary fields to local storage and backend schema.
4. Add follow-up reminders and treatment outcomes.
5. Add dealer WhatsApp lead tracking.
6. Add disease knowledge cache and Swahili content pass.
7. Add M-Pesa subscription skeleton.
8. Add B2B dashboard APIs.

## MVP Acceptance Criteria

- App starts and reaches home screen.
- User can scan using camera on a physical Android device.
- App returns a result offline using TFLite.
- Result screen shows disease name, crop, confidence, severity, treatment, dosage, and confidence guidance.
- Scan is saved locally and appears in history.
- Dealer map opens and shows nearby or cached dealers.
- Feedback can be submitted.
- Backend health check passes.
- Backend accepts scan logs and feedback.
- Backend returns dealer list, stats, and heatmap data.

## Open Decisions

- Final M-Pesa provider: Safaricom Daraja directly or aggregator.
- Admin dashboard frontend: lightweight web app or API-only first.
- Field-photo storage: Firebase Storage, S3-compatible bucket, or local pilot-only storage.
- Human agronomist escalation channel: WhatsApp link first or in-app ticket queue.
- USSD provider for feature phone roadmap.
