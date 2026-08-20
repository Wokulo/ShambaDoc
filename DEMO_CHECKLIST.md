# ShambaDoc Demo Checklist

## Pre-Demo Setup

1. **Start emulator**
   - Required: Android Emulator Hypervisor Driver installed (admin rights + reboot)
   - Or use physical Android device with USB debugging enabled
   - Verify: `flutter devices` shows the device

2. **Start backend if required**
   - Backend is deployed at `https://shambadoc-api.onrender.com`
   - Health check: `GET https://shambadoc-api.onrender.com/health`
   - If running locally: `cd backend && npm start`

3. **Confirm internet**
   - Cloud AI requires internet connectivity
   - Emulator needs network access

4. **Launch ShambaDoc**
   ```bash
   flutter pub get
   flutter run --dart-define=SHAMBADOC_API_URL=https://shambadoc-api.onrender.com/api
   ```

5. **Login**
   - App currently has no dedicated login screen
   - Firebase phone auth is implemented but not wired to UI
   - Settings screen shows "Guest Farmer" when Firebase is unavailable
   - For demo: proceed as Guest Farmer; explain Firebase auth is ready for production

6. **Open dashboard (Home tab)**
   - Verify: Welcome message, Scan Crop CTA, Quick Actions, Tips
   - All navigation buttons should be responsive

## Demo Flow

7. **Scan crop**
   - Tap "Scan Crop" or camera FAB
   - Take photo or pick from gallery
   - App attempts local AI → cloud AI → shows "Diagnosis Unavailable" if neither available
   - Show the graceful unavailable UI with "Consult Agronomist" option

8. **Show genuine AI result** (if available)
   - If cloud AI returns a result: show disease name, confidence, symptoms
   - If unavailable: do NOT fabricate; explain AI service state

9. **Save diagnosis**
   - If AI result available, save to history
   - Navigate to History tab to show saved diagnosis

10. **Open disease case**
    - From result screen, create a case
    - Show case status and expert assignment flow
    - Explain: AI → Case → Expert → Resolution workflow

11. **Find agronomist**
    - Navigate to Agronomists
    - Show verified agronomist list with specialization, location, rating
    - Demonstrate "Request Consultation" flow

12. **Request consultation**
    - Select an agronomist
    - Show consultation request form
    - Explain expert escalation pathway

13. **Show government services**
    - Navigate to Government Services
    - Show county officers, advisories, programs
    - Explain extension services connection

14. **Show agrovet**
    - Navigate to Agrovets
    - Show business listings with location and products
    - Explain input provider discovery

15. **Show SACCO**
    - Navigate to SACCOs
    - Show financing products and contact options
    - Explain agricultural financing access

16. **Show insurance**
    - Navigate to Insurance
    - Show coverage options and eligibility
    - Explain risk management for farmers

17. **Show notifications**
    - Navigate to Alerts tab
    - Show notification list (empty state if no data)
    - Explain real-time alert system

18. **Explain platform ecosystem**
    - "ShambaDoc is not just a disease scanner"
    - "It is an AI-powered Connected Agriculture Ecosystem Platform"
    - Walk through: Farmer → AI → Disease Case → Agronomist → Government → Agrovet → SACCO → Insurance → Consultation → Notifications

19. **Return to dashboard**
    - Navigate back to Home tab
    - Show scan history if any diagnoses were saved

20. **End presentation**
    - Return to Home tab
    - Summarize platform value proposition

## Emergency Procedures

### If AI fails
- Do not show fake diagnosis.
- Explain: "AI diagnosis is currently unavailable in this environment."
- Demonstrate expert consultation and ecosystem workflow instead.
- The UI clearly shows "Diagnosis Unavailable" with [Consult Agronomist] [Scan Again] [Try Another Photo]

### If backend fails
- Check API URL and internet connection.
- Restart backend if running locally.
- Do not modify code during presentation.
- Public endpoints (agronomists, agrovets, government) may still work.

### If Firebase login fails
- Use configured Firebase test authentication if available.
- For this demo: proceed as Guest Farmer.
- Do not attempt to create a new authentication system during the demo.
- Explain that Firebase phone auth is implemented and ready for production.

### If emulator fails to launch
- Check: Android Emulator Hypervisor Driver must be installed (requires admin + reboot).
- Alternative: Use physical Android device with USB debugging.
- Do not attempt to downgrade SDK components during the demo.

## Notes

- No mock predictions are shown as real AI diagnoses.
- No fake disease names or confidence scores are displayed.
- Demo data is used only for map markers and dashboard fallback.
- All protected API endpoints require Firebase authentication.
- The app gracefully handles offline, AI-unavailable, and unauthenticated states.
