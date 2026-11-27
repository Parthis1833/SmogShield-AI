# SmogShield AI — Product Requirement Document (PRD)

## 1. Executive Summary
**SmogShield AI** is a modern, GenAI-powered wellness application built for Android and Web to help families and urban communities navigate severe winter smog and urban particulate pollution. It provides real-time environmental awareness, personalized daily routines, evidence-based indoor air hygiene advice, and low-emission action tracking.

---

## 2. Core Problem Statement
During winter months across major global metropolitan centers (e.g., Indo-Gangetic Plains, North China Plain, urban valleys), nocturnal thermal inversions trap industrial emissions, crop residue smoke, and vehicular exhaust close to the ground, causing severe PM2.5 and PM10 spikes (AQI 300–500+). 

Families face three critical challenges:
1. **Misleading or Mixed AQI Scales:** Conflating US EPA AQI and Indian CPCB AQI standards, leading to false impressions of air safety.
2. **Action Paralysis:** Raw numbers without explainable, actionable guidance on when to exercise, commute, or ventilate homes.
3. **Confusion between Exposure and Emissions:** Believing that taking public transit or carpooling directly cleans their personal inhaled air, or confusing personal masking with societal carbon reduction.

---

## 3. Product Vision & Value Proposition
- **Clarity over Panic:** Meaningful, transparent air quality indices with explicit scale calibration.
- **Explainable Routine Shielding:** Explaining *why* morning runs should be shifted indoors during thermal inversions (e.g., deep-lung particulate deposition).
- **Evidence-Based Indoor Hygiene:** True HEPA (H13/H14) mechanical filtration advice while debunking dangerous pseudo-science (such as ozone generators or open-window winter airing).
- **Transparent Impact Accounting:** Tracking community CO₂e emissions avoided with transparent formulas, separated strictly from personal inhalation protection.

---

## 4. Key User Personas
1. **Urban Parent (Rohan & Priya, Delhi):** Managing school commutes and playground activities for young children (ages 4 and 9) during peak November smog episodes.
2. **Sensitive Individual / Asthma Patient (Dr. Fatima, Lahore):** Needing strict threshold warnings (AQI > 100) before planning errands or morning walks.
3. **Environmentally Conscious Commuter (Arjun, Mumbai):** Wanting to verify carbon emission savings from switching solo car trips to the metro.

---

## 5. Functional Requirements

### 5.1 Dashboard & Environmental Monitoring
- **City Selector:** Seamlessly switch between cities with simulated continuous ambient monitoring profiles (New Delhi, Lahore, Beijing, Mumbai, New York, London).
- **AQI Gauge & Category:** Visual circular arc indicator colored by official warning standards (0–50 Good, 51–100 Satisfactory, 101–200 Moderate, 201–300 Poor, 301–400 Very Poor, 401–500+ Severe).
- **Pollutant Breakdown:** Exact concentrations for PM2.5, PM10, NO₂, SO₂, CO, and O₃ with measurement units (µg/m³, mg/m³) and WHO reference levels.
- **24-Hour Pollution Trend Chart:** Hourly line chart illustrating morning thermal inversion peaks (7–9 AM) and solar dispersion windows (1–3 PM).
- **Data Integrity Banner:** Prominent mock data badge with station source and observation timestamp.

### 5.2 Conversational AI Assistant
- Responsive chat interface with user and assistant message bubbles.
- Suggested prompt chips for quick exploration.
- Simulated rule-based expert engine in Phase 1 with strict medical disclaimer; pre-configured interface for Google Gemini API integration.

### 5.3 Personalized Daily Routines
- Chronological breakdown: Morning, Afternoon, Evening, and Night routines.
- Category tagging: Commuting, School, Exercise, Home Filtration.
- Target audience badges: All Members, Children, Sensitive Groups.
- Interactive checkboxes to record daily routine completion.
- "Why this helps" scientific rationale for each recommendation.

### 5.4 Indoor Air Quality Defense
- Categorized guidance: Mechanical Filtration (HEPA H13/H14), Timed Ventilation, Indoor Source Control, and Sensor Monitoring.
- Interactive Clean Indoor Air Checklist with dynamic scoring.
- Scientific citations explaining particle dynamics and combustion byproducts.

### 5.5 Eco Impact Tracker
- Action logger with user-confirmed sustainable choices (Metro transit, carpooling, WFH, avoiding open burning, clean cooking).
- Transparent calculation formulas and documented assumptions.
- Explicit visual distinction: **Community Emissions Avoided** vs. **Personal Pulmonary Exposure Reduction**.

### 5.6 Family Profile & Vulnerability Configuration
- Household demographics (adults, children, seniors).
- Respiratory sensitivity / asthma toggle.
- Primary commute mode and home filtration setup.
- Riverpod state persistence in Phase 1, ready for Firebase Cloud Firestore sync in Phase 2.

### 5.7 Community Challenges
- Collective neighborhood smog reduction pledges.
- Participant counter, progress bar, and achievement badges.

### 5.8 Settings & Compliance
- AQI standard switcher (Indian CPCB vs. US EPA).
- Dark/Light Material 3 theme mode.
- Non-medical disclaimer and data transparency statement.

---

## 6. Non-Functional Requirements
- **Performance:** Instant sub-100ms state updates via Riverpod.
- **Accessibility:** High contrast Material 3 color tokens, scalable typography.
- **Responsiveness:** Adaptive layouts supporting compact mobile (< 768px) and wide desktop (>= 768px) with NavigationRail.
- **Safety:** Clear labeling of simulated data; zero fabricated live sensor readings.
