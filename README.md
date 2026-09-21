# AI-Based Universal Border Safety & Alert System Using Offline Geo-Fencing and Artificial Intelligence

> Offline-first Flutter Android safety prototype. Phases 1–6 provide foreground GPS, a local restricted-area polygon database, deterministic geo-fencing, and visual/voice/vibration/notification alerts. LSTM prediction, Random Forest classification, TensorFlow Lite, A* routing, and an offline LLM are planned later and are not implemented.

**IMPORTANT SCOPE (do not misrepresent in viva/docs):**
- The app does NOT know every world border. It only knows restricted areas present in the **locally stored boundary database** (`boundary-data/` → SQLite on device).
- The implemented safety pipeline is GPS → Geo-Fence → Alerts and works without a network connection after the bundled boundary data has been seeded locally. It is deterministic; it does not yet include ML, routing, or an offline LLM.
- SOS / emergency transmission requires an available communication channel. The app stores last-known location + emergency info locally; it cannot send SMS/data without signal.
- `boundary-data/sample/` polygons are **synthetic demo zones for development only**, NOT authoritative legal borders.

## Implemented architecture (Phases 1–6)

```text
GPS → GpsService → LocationModel → GeoFenceService → GeoFenceResult
                                         │
                         SQLite BoundaryRepository
                                         │
                 visual UI / AlertService → voice, vibration, notification
```

The broader ML, routing, and offline-assistant architecture remains a future plan in `docs/architecture.md` and `docs/ai_pipeline.md`.

## Repository layout

```text
.  (Flutter mobile app lives at repo root: lib/, android/, test/, pubspec.yaml)
├── ml/               Python ML pipeline (datasets, preprocessing, training, evaluation, export, models)
├── backend/          Optional FastAPI sync/update service (NOT required for core safety)
├── boundary-data/    Sample/synthetic GeoJSON + SQLite boundary datasets (demo only)
├── assets/           Flutter runtime assets (maps/, boundaries/, models/)
├── docs/             Architecture, AI pipeline, dataset, geofencing, offline mode, installation
├── scripts/          Helper scripts
├── test/             Flutter widget/unit tests (flutter test)
└── tests/            Repo-level test plans / integration scenarios
```

NOTE: The master spec suggests `mobile/` for Flutter. To avoid breaking the existing
Flutter/Gradle project created at the repo root, the Flutter app stays at the root in V1.
Treat repo root as `mobile/`.

## Technology stack (Phases 1–6)

- Flutter + Dart, Android SDK, `geolocator`, `sqflite`, `shared_preferences`,
  `flutter_tts`, `flutter_local_notifications`, and `vibration`
- Optional backend skeleton: FastAPI (see `backend/requirements.txt`); it is not required by the app.
- `ml/` contains planning/dependency scaffolding only. It has no trained models or mobile inference integration.

## Current status — Phase 6 complete

- [x] Phase 1: repository foundation
- [x] Phase 2: Flutter foundation (navigation, theme, 6 screens, widgets, APK)
- [x] Phase 3: GPS service (geolocator, permissions, validated fixes, live UI)
- [x] Phase 4: offline boundary database (sqflite, repository, GeoJSON import, seed, Home count)
- [x] Phase 5: deterministic geo-fencing (point-in-polygon, nearest enabled boundary, distance/bearing, safety states)
- [x] Phase 6: alert manager (visual, voice, vibration, notification, preferences, cooldown, escalation)
- [ ] Phase 7: LSTM movement prediction — not started

The app makes deterministic geo-fence safety decisions from validated foreground GPS fixes and enabled local boundaries. Demo polygons are synthetic and non-authoritative. ML, routing, and LLM features are not present; no model accuracy or safety prediction claims are made.

## Setup and verification

Requires: Flutter SDK, Dart SDK, Android Studio / Android SDK, Git, Python 3.10+.

```powershell
flutter --version
flutter pub get
flutter analyze
flutter test
```

Python pipelines (structure only in Phase 1, no training yet):

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r ml\requirements.txt
pip install -r backend\requirements.txt
```

## Offline behavior and future work

The bundled synthetic boundary data is seeded into SQLite and the deterministic GPS → geo-fence → alert pipeline does not require a network connection. Offline map tiles, download-region workflows, ML risk prediction, safe routing, and an offline LLM are future work.

## Documentation

- `docs/architecture.md` — system data flow
- `docs/ai_pipeline.md` — LSTM + Random Forest plan (no fake results)
- `docs/dataset.md` — synthetic trajectory plan + schema
- `docs/geofencing.md` — point-in-polygon / distance / states
- `docs/offline_mode.md` — what works offline vs online
- `docs/installation.md` — environment setup
- `boundary-data/README.md` — demo data disclaimer

## Current limitations

- GPS and alerts operate while the Flutter app is in the foreground; background tracking is not implemented.
- Demo boundaries are synthetic and must not be used as authoritative geographic or legal data.
- No `.tflite` models exist yet.
- Backend is a stub; core app must never depend on it.
- Phase 7 has not started.
