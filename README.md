# SmogShield AI — GenAI-Powered Clean Air Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.47.1-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.1-blue.svg)](https://dart.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green.svg)](https://fastapi.tiangolo.com)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20Web-teal.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

**SmogShield AI** is a modern, GenAI-powered wellness application built for Android and Web to help families and communities manage severe winter smog and urban air pollution.

---

## 🌟 Key Features

1. **Environmental Home Dashboard:**
   - Real-time observation switcher across global smog-impacted cities (New Delhi, Lahore, Beijing, Mumbai, New York, London).
   - Optional live OpenAQ station monitoring by GPS or city/place search, with station metadata, recent concentrations, and measurement-aware recommendations.
   - Semi-circular AQI index gauge with color-coded severity categories.
   - Comprehensive multi-pollutant breakdown (PM2.5, PM10, NO₂, SO₂, CO, O₃) with measurement units and WHO reference comparisons.
   - Interactive 24-hour pollution trend chart showing morning thermal inversion peaks and afternoon solar dispersion dips.
   - Prominent mock data integrity banner with station name and observation timestamp.
2. **Conversational AI Assistant:**
   - Responsive chat interface with suggested prompt chips.
   - FastAPI-backed Gemini responses; rule-based simulated responses are available only when `DEMO_MODE` is explicitly enabled.
3. **Personalized Daily Routine:**
   - Chronological breakdown (Morning, Afternoon, Evening, Night) covering exercise, commuting, school safety, and bedroom filtration.
   - Interactive checkboxes to track daily smog shielding habits.
   - Clear scientific explanations for *why* each recommendation reduces pulmonary risk.
4. **Indoor Air Quality & Clean Air Audit:**
   - Evidence-based advice on true HEPA (H13/H14) mechanical filtration, timed solar-inversion ventilation, and indoor combustion elimination (incense, frying).
   - Interactive home clean air readiness audit checklist.
5. **Eco Impact Tracker:**
   - Log user-confirmed sustainable actions (metro transit, carpooling, WFH, avoiding open burning).
   - Transparent calculation formulas and documented assumptions.
   - **Critical Safety Distinction:** Explicit visual separation between societal greenhouse gas / emissions savings and individual personal exposure reduction.
6. **Family Profile & Vulnerability:**
   - Household demographics (adults, children, seniors).
   - Respiratory vulnerability / asthma toggle for stricter exposure limits.
7. **Community Challenges:**
   - Join collective neighborhood clean-air drives (7-Day Winter Smog Shield, Car-Free Wednesday).
8. **Settings & Scale Accuracy:**
   - Indian CPCB AQI vs. US EPA AQI standard switcher — scales are never mixed.
   - Full Material 3 Light and Dark theme modes.

---

## 🏗️ Architecture

- **Frontend:** Flutter + Dart (Material 3, Riverpod 3, GoRouter 18, FL Chart)
- **Backend:** Python 3.13 FastAPI + Pydantic v2 + Uvicorn
- **AI Integration:** Google Gemini API abstraction (`gemini_service.py` & `gemini_service.dart`)
- **Database / Auth:** Firebase Authentication & Cloud Firestore abstractions (`firebase_service.dart` & `firebase_service.py`)

```
smogshield_ai/
├── lib/
│   ├── app/              # Router, AppShell (responsive rail / bottom bar)
│   ├── core/
│   │   ├── constants/    # Palette, AQI standards
│   │   ├── data/         # Mock repositories & Riverpod notifiers
│   │   ├── models/       # Typed domain models
│   │   ├── services/     # Gemini, Firebase, ApiClient abstractions
│   │   ├── theme/        # Material 3 light/dark themes
│   │   └── widgets/      # AQI gauge, trend chart, pollutant grid, mock banner
│   └── features/         # Dashboard, Assistant, Routine, Impact, Indoor Air, etc.
├── backend/
│   ├── app/              # FastAPI application, models, services
│   ├── tests/            # Pytest test suite
│   ├── requirements.txt  # Python dependencies
│   └── .env.example      # Environment template
└── test/                 # Flutter unit & widget tests
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **Flutter SDK:** 3.47+ (Dart 3.13+)
- **Python:** 3.10+
- **Google Chrome** (for web development)
- **Android Studio & SDK** (for Android development)

### 2. Run Flutter App
```bash
# Get dependencies
flutter pub get

# Run static analysis (0 issues)
flutter analyze

# Run unit and widget tests (11/11 passed)
flutter test

# Run on Web (Chrome)
flutter run -d chrome --dart-define-from-file=config/frontend.json

# Build for Web
flutter build web --dart-define-from-file=config/frontend.json
```

### 3. Run FastAPI Backend
```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt

# Copy .env.example to .env and fill your secure local configuration. Never commit it.
cp .env.example .env

# Run FastAPI backend with hot reload
uvicorn app.main:app --reload --port 8000

# Run backend tests (8/8 passed)
python3 -m pytest
```

Open interactive Swagger API documentation at: `http://127.0.0.1:8000/docs`

### Live OpenAQ monitoring
- Set `OPENAQ_API_KEY` and `GOOGLE_MAPS_API_KEY` in `backend/.env`. They are sent only by FastAPI to their upstream services and must never be added to Flutter configuration. Enable Places API (New) with billing for city autocomplete and restrict this server key to the required API and backend egress where supported.
- Configure Google Cloud quotas for autocomplete usage. The client debounces input by 400 ms and requests at most five suggestions per call.
- City search and selected-place resolution require a Firebase ID token. Configure Firebase Authentication in Firebase Console and enable Email/Password and Google sign-in providers. Configure the backend Admin SDK with `FIREBASE_SERVICE_ACCOUNT_PATH`. Supply Firebase client options through `config/frontend.json`; these client values are not backend secrets.
- The backend limits city autocomplete and place-details requests to 30 requests per minute per client IP and endpoint. This in-memory limit is per backend process; use an API gateway or shared limiter for multi-worker deployments.
- If an OpenAQ key has been exposed, revoke it with OpenAQ and create a replacement. Do not copy the previously exposed value.
- Start the backend before selecting **Use GPS** or **Search a place** in the dashboard. `config/frontend.json` selects `http://10.0.2.2:8000` for Android emulators and `http://localhost:8000` for Web. Change `API_BASE_URL_ANDROID` or `API_BASE_URL_WEB` there for other development hosts. Android permits local HTTP only in debug builds; use HTTPS for deployed services.
- GPS access requires the device/browser location permission. Browser geolocation requires a secure context (HTTPS, or localhost during development). Place search is available when location access is unavailable.
- Live readings are pollutant concentrations with source-provided units and timestamps. The live view intentionally does not calculate or display AQI until an averaging-period-aware AQI implementation is selected.
- City search uses authenticated `GET /api/v1/locations/search?q={text}&session_token={uuid}` (Google Places Autocomplete New), followed by authenticated `GET /api/v1/locations/details?place_id={id}&session_token={uuid}` after a user selects a specific result. Autocomplete suggestions include city/display metadata; the details response provides the selected place's state, country, latitude, and longitude. Flutter debounces requests, sends Firebase ID tokens to FastAPI, and reuses a UUID session token through selection. Selecting a result refreshes nearby air-quality readings by its resolved coordinates. The UI displays Google attribution; retain the required Google Maps attribution/logo if changing the suggestion presentation.
- Nearby measurements use `GET /api/v1/air-quality/nearby?lat={lat}&lon={lon}` with optional selected-place metadata. Search results are geocoded first and then sent as coordinates to this endpoint. `GET /api/v1/air-quality/search?query={place}` remains a legacy OpenAQ station-name search and is not the city geocoder.
- With FastAPI running, verify the Flutter repository can reach it using `flutter test --dart-define=SMOGSHIELD_INTEGRATION_API_BASE_URL=http://127.0.0.1:8000 test/openaq_backend_integration_test.dart`.
- Nearby search expands through 5 km, 10 km, 15 km, 20 km, and 25 km. To cover 25–30 km without exceeding OpenAQ's 25 km per-query radius, it also searches eight overlapping locations offset 6 km from the requested coordinates, deduplicates location IDs, and filters every result by its original-coordinate Haversine distance. Stations over 30 km are excluded. It selects the nearest station with at least one valid measurement no older than 24 hours. Freshness defaults are 60 minutes (Fresh), 6 hours (Delayed), and 24 hours maximum (Stale but still reportable); configure `AIR_QUALITY_FRESH_MINUTES`, `AIR_QUALITY_DELAYED_MINUTES`, and `AIR_QUALITY_MAX_AGE_MINUTES` in the backend environment.
- An optional `SECONDARY_AIR_QUALITY_URL` may point to a provider adapter endpoint that accepts `lat` and `lon` and returns normalized station coordinates and timestamped measurement values. Configure its API key separately if required. Provider values are validated and are never synthesized. Cached results are process-memory only and are returned with `is_cached: true`.

### Firebase Admin and Gemini configuration
- Copy [`backend/.env.example`](backend/.env.example) to `backend/.env`. The backend loads that exact path before importing its Firebase services. Keep the Firebase Admin JSON at `backend/secrets/firebase-service-account.json` with owner-only permissions; configure `FIREBASE_SERVICE_ACCOUNT_PATH=secrets/firebase-service-account.json`. The secrets directory and `.env` files are ignored by Git.
- Revoke any previously exposed Firebase service-account key in Google Cloud IAM and generate a replacement JSON locally. Do not put Firebase private keys or service-account emails in `GEMINI_API_KEY`; configure a separate Google AI API key. Missing/invalid Gemini configuration returns an unavailable response rather than fabricated AI output.
- Copy [`config/frontend.example.json`](config/frontend.example.json) to `config/frontend.json`, then supply the existing Firebase client values and backend URLs. Run Flutter with `flutter run -d chrome --dart-define-from-file=config/frontend.json` or `flutter run -d <android-device> --dart-define-from-file=config/frontend.json`. Set `DEMO_MODE` to `"true"` only when intentionally demonstrating the simulated assistant.
- Firebase client API keys and app IDs are included in compiled Flutter apps and are publicly visible. They are not substitutes for backend credentials; apply Firebase API restrictions and do not place Gemini, OpenAQ, Google Places, or Firebase Admin credentials in frontend configuration. The tracked Android `google-services.json` remains required by the Google Services Gradle plugin and must match the configured Android Firebase app.

---

## 🧪 Phase 1 Quality Gate & Verification Status

A rigorous Phase 1 Quality Gate was executed across static analysis, unit/widget testing, web compilation, backend testing, responsive viewport validation, secrets auditing, and platform readiness.

| Quality Gate Check | Tool / Framework | Result | Details & Verified Invariants |
|---|---|---|---|
| **Static Code Analysis** | `flutter analyze` | **PASSED (0 issues)** | Zero warnings, zero errors, zero lints across entire `lib/` and `test/` tree. |
| **Flutter Test Suite** | `flutter test` | **PASSED (46/46)** | 46 comprehensive tests across 8 test suites passing in 2.2s. |
| **Web Runtime Execution** | `flutter test --platform chrome` | **PASSED (11/11)** | Verified full execution in Google Chrome 157 headless runtime. |
| **Web Production Build** | `flutter build web` | **PASSED** | Clean production bundle generated in `build/web` (22.8s). |
| **FastAPI Backend Pytest** | `pytest` (Python 3.13) | **PASSED (8/8)** | Health, air quality mock contract, simulated assistant, routines, indoor tips, and impact benchmarks. |
| **Indian AQI Category Exact Boundaries** | Dart Unit Tests | **PASSED** | Validated exact CPCB thresholds: 0–50 Good, 51–100 Satisfactory, 101–200 Moderate, 201–300 Poor, 301–400 Very Poor (Mock 342), 401+ Severe. |
| **Five Navigation Destinations** | GoRouter + Widget Tests | **PASSED** | Verified seamless switching across `/` (Dashboard), `/assistant`, `/routine`, `/impact`, and `/profile`. |
| **Assistant Message Input & Validation** | Widget Tests | **PASSED** | Send button disabled on empty/whitespace input; text input, keyboard send (`TextInputAction.send`), and suggested prompt chips verified. |
| **Daily Routine Explanatory Cards** | Widget Tests | **PASSED** | Verified time, action, and scientific rationale ("Why it matters:"), period filtering chips, and checkbox completion toggles. |
| **Profile Demographics & Vulnerability** | Widget Tests | **PASSED** | Household member increment/decrement counters, asthma vulnerability switch, and local session disclaimer verified. |
| **Sample Impact Logging & Distinctions** | Widget Tests | **PASSED** | Action session logging, CO2e summation, formula transparency, and explicit separation of emissions savings vs. personal exposure reduction verified. |
| **Mobile & Desktop Viewport Responsiveness** | Flutter Widget Tester | **PASSED** | Zero `RenderFlex` overflow errors verified at narrow mobile (360px) and wide desktop (1280px); automatic switching between `NavigationBar` and `NavigationRail`. |
| **Explicit Demonstration Data Watermarks** | Widget Tests | **PASSED** | Verified `DEMO DATA — NOT LIVE`, `Demonstration Data — Not Actual Current Conditions`, and non-medical wellness disclaimers. |
| **API Schema Synchronization** | Cross-Framework Tests | **PASSED** | Flutter Pydantic-compatible JSON deserializers (`AirQuality`, `AssistantMessage`, `RoutineItem`, `ImpactAction`) validated against FastAPI payload schemas. |
| **Secrets & Credential Audit** | Grep Regex Scan | **PASSED** | Zero hardcoded API keys, passwords, or cloud credentials found in source files. |
| **Android SDK & Scaffolding** | Android SDK 36 | **VERIFIED** | Scaffolding generated (`AndroidManifest.xml`, Gradle build scripts); configured AVD `Medium_Phone_API_36.0` present. |

### 🔍 Clear Feature Testing Status (Tested vs. Untested / Roadmap)

#### ✅ Tested & Verified in Phase 1:
- **Indian National AQI Presentation:** Precise 6-stage color coding, CPCB category labels, multi-pollutant measurements with units (`µg/m³`, `mg/m³`), source metadata, and observation timestamps.
- **Explicit Demonstration Guardrails:** Prominent yellow/dark warning banners stating mock AQI 342 is simulated demonstration data and not actual conditions.
- **Rule-Based Assistant Simulation (`simulated_rules_v1`):** Safe, deterministic environmental advice covering exercise, HEPA purifiers, commuting, N95 masks, and ventilation, with strict non-medical disclaimers.
- **Explanatory Routine Guidance:** Time-stamped daily habits with explicit scientific justifications and interactive habit tracking.
- **Local Profile & Demographics:** In-memory Riverpod state for household size, asthma vulnerability, and commute modes.
- **Eco Impact Calculation:** Documented formulas (`0.14 kg CO₂e/km`, etc.) with transparent assumptions and explicit exposure vs. societal emission boundaries.
- **Responsive Navigation:** Bottom `NavigationBar` for mobile viewports (<600px) and `NavigationRail` for desktop viewports (≥600px).
- **FastAPI Backend:** Fully operational RESTful service matching Flutter client models.

#### ⏳ Untested in Sandbox / Planned for Phase 4:
- **Live Gemini API Execution:** Phase 1 uses rule-based simulation (`SimulatedGeminiService`). Live Google Gemini 1.5/2.0 API calls require API keys configured in Phase 4.
- **Firebase Auth & Cloud Firestore Sync:** User preferences and routine completions are stored in Riverpod in-memory state. Cloud persistence is architected for Phase 2.
- **Physical Android Device / Headless Emulator UI Run:** Android SDK and AVD `Medium_Phone_API_36.0` are present, but interactive license acceptance (`flutter doctor --android-licenses`) and sandbox network download limits on Gradle wrapper distributions prevented running a live emulator session. Web (Chrome) runtime execution was verified instead.
- **Live Hardware Sensors / Real-Time Telemetry:** Ambient air quality measurements are demonstration data; live sensor streaming and CPCB/OpenAQ API ingestion will connect in Phase 4.

---

## 🔒 Data Safety & Ethical AI Principles

1. **Never Fabricate Live AQI:** All ambient air quality figures in Phase 1 are explicitly watermarked and badge-labeled as `DEMO DATA — NOT LIVE`.
2. **Never Mix AQI Scales:** Indian National AQI (CPCB) and US EPA AQI have distinct mathematical breakpoints and are maintained as separate selectable standards.
3. **No Medical Claims:** The application explicitly states that it provides environmental wellness guidance, not medical diagnosis or clinical treatment.
4. **Honest AI Status:** The Phase 1 assistant clearly discloses that it operates in simulated mode, without falsely claiming live Gemini API execution until cloud credentials and pipelines are established.
