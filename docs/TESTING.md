# Verification & Testing Framework — Border Safety Alert System (BSAS)

**Version:** 1.1.0  
**Status:** All Automated Test Suites Passing  
**Document Generated:** September 23, 2026  

---

## 1. Test Execution Commands

### 1.1 Mobile Client (Flutter & Dart)
```bash
# Static analysis and linting (0 issues)
dart analyze lib/

# Run complete unit, widget, and integration test suite (97 tests)
flutter test --no-pub
```

### 1.2 Backend API (FastAPI & Pytest)
```bash
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run backend unit and integration test suite
pytest backend/tests -v
```

### 1.3 Operations Dashboard (Next.js & TypeScript)
```bash
cd frontend

# Linting
npm run lint

# TypeScript verification and production build
npm run build
```

---

## 2. Test Suites Overview

### 2.1 Mobile Test Coverage (`test/`)
- `geofence_service_test.dart`: Sub-meter point-in-polygon tests (inside, approaching, outside, boundary crossing).
- `geo_math_test.dart`: Haversine distance, cross-track distance, and bearing delta calculations.
- `ai_prediction_service_test.dart`: LSTM feature extraction pipeline, RobustScaler normalization, and Random Forest decision trees.
- `risk_engine_test.dart`: Deterministic fusion logic verifying that geofence breaches cannot be overridden.
- `alert_service_test.dart`: Multi-modal dispatch (sound, vibration, TTS, notifications) and duplicate suppression.
- `routing_service_test.dart`: A* obstacle avoidance calculating escape corridors around restricted polygons.
- `offline_map_service_test.dart`: Tile counting, SHA-256 manifest verification, and offline tile resolution.
- `local_chat_service_test.dart`: Dual-backend inference, streaming token parsing, and read-only safety snapshot guardrails.
- `boundary_repository_test.dart`: SQLite CRUD, batch upsert, and schema migration integrity.
- `navigation_test.dart`: Widget test verifying screen keys, tab transitions, and backstack navigation.

### 2.2 Backend Test Coverage (`backend/tests/`)
- `test_auth.py`: Bcrypt password hashing, JWT creation, token expiration, and invalid signature rejection.
- `test_zones.py`: Geospatial boundary query endpoints, GeoJSON parsing, and boundary CRUD.
- `test_events.py`: Incident logging, severity categorization, and query filtering.
- `test_sync.py`: Offline-first batch event synchronization and idempotency deduplication.
- `test_dashboard.py`: Statistics aggregation, active alert counts, and live sector summaries.

---

## 3. Physical Android Hardware Verification

### 3.1 Device Specifications
- **Device Model:** Samsung Galaxy A12s (`SM-A127F`)
- **Android Version:** Android 13 (API 33, Tiramisu)
- **CPU Architecture:** ARM64 (`arm64-v8a`)
- **Serial Number:** `RZ8RC0FB4GY`

### 3.2 Hardware Tests Executed
1. **Application Launch & Animated Branding:** Verified smooth 60fps launch and splash radar animation.
2. **TensorFlow Lite Runtime:** Logcat confirmed `Initialized TensorFlow Lite runtime` on ARM64.
3. **Android Text-to-Speech (TTS):** Logcat confirmed native voice engine binding with zero exceptions.
4. **Offline Map Rendering:** Logcat confirmed zero network crashes when disconnected, rendering from `/sdcard/Download/bsas_offline_tiles`.
5. **System Back Navigation:** Verified Android gesture and hardware back button behavior without ANR.
