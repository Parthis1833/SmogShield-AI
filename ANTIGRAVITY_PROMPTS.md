# Antigravity implementation prompts
## Prompt 1 — Import and verify
Open this repository. Do not replace functioning starter files. Check Flutter and Dart versions; run `flutter create . --platforms=android,web`, `flutter pub get`, `flutter analyze` and `flutter test`. Fix compilation and test errors while preserving explicit mock labels. Run Chrome and inspect all five screens. Summarize changes and show exact commands and results. Do not claim success without executing tests.

## Prompt 2 — Refine UI
Refactor the existing Flutter screens into a premium responsive Material 3 environmental dashboard. Retain GoRouter and Riverpod, mock repository, safe disclaimers, and working routes. Add mobile and desktop layouts, clear Indian AQI category visuals, loading/empty/error states and semantic labels. Test 360px mobile and 1280px desktop widths. Do not introduce fake live values.

## Prompt 3 — Prepare Firebase Phase 2
Do not add secrets. Propose a Firebase Auth/Firestore implementation plan with app initialization only after `flutterfire configure`. Draft data schema, least-privilege household security rules, user consent and Android/Web auth flow. Wait for the project's actual Firebase configuration before connecting services. Preserve standalone mock mode.

## Prompt 4 — Prepare FastAPI and Gemini Phase 4
Inspect existing backend. Create typed API schemas and a repository interface that Flutter can consume. Keep mock endpoint responses labeled `is_mock=true`. Propose a secure Gemini integration with server-side API keys, Firebase ID-token verification, rate limiting, grounded tool inputs, safety-rule validation and a deterministic fallback. Do not activate live service without credentials and approved data sources.

## Prompt 5 — Quality gate
Run static analysis, Flutter unit/widget tests, FastAPI tests, Android emulator smoke tests and Chrome navigation tests. Report pass/fail individually, capture reproducible failures and fix them. Confirm no secrets exist and all sample observations are labeled mock.
