# SmogShield AI — Architecture Specification

## 1. Architectural Overview
SmogShield AI is architected using a **Feature-First Clean Architecture** in Flutter (frontend) coupled with a modular **Python FastAPI** microservice (backend). The architecture decouples the presentation layer, business logic (state notifiers), and domain models from data providers and external services (Firebase, Gemini API).

```
                      ┌────────────────────────────────────────┐
                      │          Flutter Presentation          │
                      │  (Material 3 / Responsive AppShell)    │
                      └──────────────────┬─────────────────────┘
                                         │
                      ┌──────────────────▼─────────────────────┐
                      │           Riverpod Layer               │
                      │  (Notifiers, State Providers, Router)  │
                      └──────────┬───────────────────┬─────────┘
                                 │                   │
            ┌────────────────────▼─────┐       ┌─────▼────────────────────┐
            │   Domain Models & Data   │       │   Services & Adapters    │
            │   AirQuality, Routines,  │       │   GeminiService,         │
            │   ImpactActions, Profile │       │   FirebaseService,       │
            └──────────────────────────┘       │   ApiClient              │
                                               └──────────────┬───────────┘
                                                              │
                                               ┌──────────────▼───────────┐
                                               │   FastAPI Python Backend │
                                               │   /health, /air-quality, │
                                               │   /assistant, /routines  │
                                               └──────────────────────────┘
```

---

## 2. Directory Structure

```
lib/
├── main.dart                          # Application bootstrap & ProviderScope
├── app/
│   ├── app.dart                       # SmogShieldApp & responsive AppShell (Mobile/Desktop)
│   └── router.dart                    # GoRouter route declarations & ShellRoute
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Material 3 tokens, Forest Green/Teal, AQI colors
│   │   └── aqi_standards.dart         # CPCB & US EPA scale definitions
│   ├── data/
│   │   └── mock_repository.dart       # MockAirQualityRepository & Riverpod Notifiers
│   ├── models/
│   │   ├── air_quality.dart           # AirQuality, HourlyAqi, Pollutant readings
│   │   ├── assistant_message.dart     # Conversational messages & suggestions
│   │   ├── community_challenge.dart   # Community challenges & pledges
│   │   ├── family_profile.dart        # Household demographics & preferences
│   │   ├── impact_action.dart         # CO2e savings models & formulas
│   │   ├── indoor_tip.dart            # Evidence-based indoor advice
│   │   └── routine_item.dart          # Daily routines & scientific rationales
│   ├── services/
│   │   ├── api_client.dart            # HTTP client for FastAPI backend
│   │   ├── firebase_service.dart      # Prepared Auth & Firestore abstractions
│   │   └── gemini_service.dart        # Gemini GenAI service abstraction & mock
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light & dark theme definitions
│   └── widgets/
│       ├── aqi_gauge.dart             # Circular/progress AQI indicator & health advisory
│       ├── mock_data_banner.dart      # Explicit data safety banner
│       ├── pollutant_grid.dart        # Multi-pollutant breakdown cards
│       ├── section_card.dart          # Reusable card container & page headings
│       └── trend_chart.dart           # 24-hour fl_chart hourly pollution graph
└── features/
    ├── assistant/                     # GenAI chat UI & suggestions
    ├── community/                     # Neighborhood clean-air challenges
    ├── dashboard/                     # Air quality monitoring & insights
    ├── impact/                        # Carbon savings & exposure distinction
    ├── indoor_air/                    # HEPA filtration & clean indoor air audit
    ├── onboarding/                    # App introduction & pillar walkthrough
    ├── profile/                       # Family demographics & vulnerability settings
    ├── routine/                       # Chronological routine recommendations
    └── settings/                      # AQI standards, themes, and disclaimers
```

---

## 3. State Management (Riverpod 3)
Riverpod 3 is used throughout the application to manage reactive state:
- `airQualityProvider`: FutureProvider retrieving active city data from the repository.
- `selectedCityProvider`: NotifierProvider tracking the currently observed city.
- `routineProvider`: NotifierProvider managing daily routine checklists and completion state.
- `impactProvider`: NotifierProvider managing confirmed sustainable actions, cumulative CO₂e savings, and session logs.
- `familyProfileProvider`: NotifierProvider maintaining household profile demographics and vulnerability flags.
- `themeModeProvider`: NotifierProvider handling runtime Light / Dark / System theme switching.
- `aqiStandardProvider`: NotifierProvider managing Indian CPCB vs. US EPA standard calculations.

---

## 4. Navigation Architecture (GoRouter)
- **Top-Level Route:** `/onboarding` for first-time user orientation.
- **ShellRoute:** Wraps all primary functional screens inside an adaptive shell:
  - Mobile (< 768px): Uses `NavigationBar` at bottom with top `AppBar`.
  - Desktop / Web (>= 768px): Uses `NavigationRail` alongside content with max-width container constraints (980px).
- **Core Screen Paths:**
  - `/` (Home Dashboard)
  - `/assistant` (AI Assistant)
  - `/routine` (Daily Routine)
  - `/impact` (Eco Impact Tracker)
  - `/profile` (Family Profile)
  - `/indoor-air` (Indoor Air Quality)
  - `/community` (Community Challenges)
  - `/settings` (Settings & Standards)

---

## 5. Backend Architecture (Python FastAPI)
The FastAPI backend (`backend/app/`) runs asynchronously on Uvicorn:
- **Pydantic v2 Models (`models.py`):** Strongly typed request/response schemas with field validation and documentation.
- **CORS Middleware:** Enabled for cross-origin web requests from Flutter Web (`localhost:*`).
- **Endpoints:**
  - `GET /health`: Microservice health check and mock mode confirmation.
  - `GET /api/v1/air-quality/nearby`: Requires `lat` and `lon`; accepts optional `city`, `state`, `country`, and `display_name`. Returns station metadata, source-reported pollutant concentrations, units, timestamps, freshness, and provider/cache status. This endpoint does not return or infer AQI.
  - `POST /api/v1/assistant`: Accepts user question and family context, routing through `GeminiService`.
  - `GET /api/v1/routines`: Time-of-day scheduled smog guidance.
  - `GET /api/v1/indoor-tips`: Evidence-based ventilation and filtration tips.
  - `GET /api/v1/impact/benchmarks`: Verified transport emission factors with calculations.

---

## 6. Firebase & Gemini Integration Blueprint
The codebase is structured to facilitate zero-friction cloud integration in Phases 2 and 4:
1. **Firebase Authentication & Firestore:** `lib/core/services/firebase_service.dart` defines `AuthService` and `FirestoreSyncService`. When `flutterfire configure` is executed, the mock classes are swapped with Firebase SDK calls without altering UI code.
2. **Google Gemini API:** `backend/app/services/gemini_service.py` inspects the `GEMINI_API_KEY` environment variable. When supplied, it interfaces with Google GenAI (`google-genai` / Gemini 1.5/2.0 API); otherwise, it falls back gracefully to the validated rule-based expert engine.
