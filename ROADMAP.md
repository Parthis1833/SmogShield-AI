# SmogShield AI — Product Roadmap

## Phase 1: Foundation & Core Experience (Current — Complete)
- [x] Flutter multiplatform project scaffolding (Android & Web).
- [x] Material 3 Environmental Wellness Design System (Forest Green, Teal, Mint, AQI warning tokens).
- [x] 10 Connected Screens: Dashboard, Assistant, Routine, Indoor Air, Impact, Profile, Community, Settings, Onboarding.
- [x] Adaptive Responsive Shell: Bottom NavigationBar on mobile, NavigationRail on desktop/web.
- [x] Riverpod 3 State Management with typed Notifiers.
- [x] GoRouter declarative routing.
- [x] 24-Hour hourly pollution trend visualization using `fl_chart`.
- [x] Multi-city simulated data (New Delhi, Lahore, Beijing, Mumbai, New York, London).
- [x] Separate AQI scales: Indian CPCB vs. US EPA.
- [x] Transparent Eco Impact calculator with explicit exposure vs. emissions distinction.
- [x] FastAPI mock backend with Pydantic v2 schemas and CORS.
- [x] Unit, widget, and backend pytest suites (100% passing).

---

## Phase 2: Cloud Sync & Authentication (Upcoming)
- [ ] Install `firebase_core`, `firebase_auth`, `cloud_firestore`.
- [ ] Configure FlutterFire CLI for Android and Web.
- [ ] Anonymous guest sign-in with Google Sign-In linking.
- [ ] Cloud Firestore synchronization for family profiles and logged impact actions.
- [ ] Offline-first persistence with Firestore cache.

---

## Phase 3: Live Sensor Ingestion & Meteorological Forecasts
- [ ] Integrate official CPCB / OpenAQ / AirNow live station APIs.
- [ ] Integrate meteorological data (boundary layer height, temperature inversion forecasts, wind speed).
- [ ] Automated push notifications for morning PM2.5 spikes.
- [ ] Graceful fallback to cached data when official monitoring stations experience telemetry downtime.

---

## Phase 4: Gemini 1.5/2.0 Real-Time GenAI Assistant
- [ ] Connect FastAPI backend to Google Gemini 1.5 Pro / Flash API via official Google GenAI SDK.
- [ ] Multi-turn conversational memory with family profile grounding.
- [ ] Multi-modal image analysis (upload photo of window seal, filter, or smog horizon to assess condition).
- [ ] Audio/voice interface for hands-free morning smog queries.

---

## Phase 5: Community Network & IoT Air Monitor Pairing
- [ ] Bluetooth LE / Wi-Fi pairing with consumer indoor air monitors (e.g., Sensirion, AirGradient, IQAir).
- [ ] Hyperlocal neighborhood air quality sharing.
- [ ] School clean-corridor community monitoring and anti-idling tracking.
