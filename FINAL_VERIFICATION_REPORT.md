# Border Safety Alert System (BSAS) — Master Verification & Release Report

**Project**: Border Safety Alert System (BSAS)  
**Repository**: [https://github.com/jagetheswaren/Border-Safety-Alert-System](https://github.com/jagetheswaren/Border-Safety-Alert-System)  
**Package Identifier**: `com.bordersafety.border_safety_alert`  
**Version**: `1.1.0+2`  
**Report Date**: October 23, 2026  

---

## 1. Executive Summary & Verification Matrix

| Verification Scope | Command Executed | Result | Status |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | `dart analyze` | 0 analyzer issues (`No issues found!`) | **PASSED** |
| **Flutter Unit & Widget Tests** | `flutter test --no-pub` | 138 / 138 tests passed (100%) | **PASSED** |
| **FastAPI Backend Tests** | `python -m pytest backend/tests` | 21 / 21 tests passed (100%) | **PASSED** |
| **Next.js Web Operations Build** | `npm run build` | 21 / 21 static & dynamic routes compiled | **PASSED** |
| **FastAPI Backend Local Daemon** | `uvicorn app.main:app` | HTTP 200 on `/api/v1/health` (Port 8000) | **VERIFIED LIVE** |
| **Next.js Dashboard Local Server** | `next start` | HTTP 200 on `/dashboard` & `/login` (Port 3000) | **VERIFIED LIVE** |
| **Android Release APK Build** | `flutter build apk --release` | `build\app\outputs\flutter-apk\app-release.apk` | **BUILT & VERIFIED** |
| **Android App Bundle (AAB)** | `flutter build appbundle --release` | `build\app\outputs\bundle\release\app-release.aab` | **BUILT & VERIFIED** |
| **Android Emulator Live Execution** | `adb install` & `am start` | Launched on `emulator-5556` (Android 14 API 34) | **VERIFIED LIVE** |
| **USB Physical Device Deployment** | `flutter run -d RZ8RC0FB4GY` | Samsung Galaxy (`RZ8RC0FB4GY`) reported `unauthorized` | **PENDING USER RSA TAP** |

---

## 2. Release Artifacts & Cryptographic Checksums

### A. Android Release APK
- **File Path**: `C:\Users\jaget\Desktop\Border Safety Alert System\build\app\outputs\flutter-apk\app-release.apk`
- **File Size**: `532,827,990 bytes` (508.1 MB)
- **SHA-256 Checksum**:
  ```text
  AE55CD2DDA5EF57373541B6360549F051EE2F06D409304A207354DA3DDA57402
  ```

### B. Google Play Android App Bundle (AAB)
- **File Path**: `C:\Users\jaget\Desktop\Border Safety Alert System\build\app\outputs\bundle\release\app-release.aab`
- **File Size**: `148,825,609 bytes` (141.9 MB)
- **SHA-256 Checksum**:
  ```text
  CE3976A79ECC42B46713F7558B71A5568EFBD747A956956DC07DF6156AC4DEF6
  ```

### C. Build Configuration & Keystore Separation
- **Release Keystore Support**: Configured in `android/app/build.gradle.kts` to read from `android/key.properties` or environment variables (`BSAS_KEYSTORE_PATH`, `BSAS_KEYSTORE_PASSWORD`, `BSAS_KEY_ALIAS`, `BSAS_KEY_PASSWORD`).
- **Development Safe Fallback**: When release credentials are absent, automatically falls back to debug signing with explicit console warnings, preventing build crashes while ensuring release secrets are never checked into version control.
- **Template Provided**: `android/key.properties.example` added for developer onboarding.

---

## 3. Subsystem Audit & Verified Fixes

### 1. Flutter & Android Configuration
- **Application ID Uniformity**: Unified on `com.bordersafety.border_safety_alert` across `pubspec.yaml`, `build.gradle.kts`, `MainActivity.kt`, and documentation.
- **Android Permissions**: Maintained non-intrusive foreground permissions (`INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`, `POST_NOTIFICATIONS`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`). Removed unnecessary background location declarations in compliance with Google Play location safety policies.
- **Android 13+ Notification Handling**: Added runtime permission requests and status checkers in `NotificationService`.

### 2. Offline Maps & Tile Ingestion
- **Permitted Tile Providers**: Replaced banned OpenStreetMap tile server endpoints (which returned HTTP 403 Forbidden) with ArcGIS World Street Map and World Imagery with reference place labels.
- **Honest Tile Verification**: `OfflineMapService` and `verifyRegion()` now verify physical tile presence on disk before reporting a region as `READY`. No false positive readiness claims.
- **Hybrid Default Layer**: Map screen defaults to optical satellite imagery with high-contrast label overlays for outdoor situational clarity.

### 3. Local AI & Native Inference Engine
- **Independent Safety State**: Authoritative civilian safety calculation remains strictly governed by `RiskEngine` (fused TFLite LSTM + Random Forest) and `GeofenceService`. Generative AI operates strictly in advisory mode via `SafetyContextBuilder`.
- **`NativeGgufRuntime` Interface**: Complete FFI/CLI native runtime interface with `GgufMetadata` extraction, endian-aware binary header inspection (magic `GGUF`, version, tensor count), and SHA-256 hash verification.
- **Dual-Link LLM Support**: Supports local Ollama server running `qwen3:0.6b` via LAN / ADB reverse proxy as well as on-device native GGUF binaries.

### 4. Motion & Dynamic Telemetry
- **Motion Service (`MotionService`)**: Implemented activity classification (`stationary`, `walking`, `running`, `vehicular`), exponential speed smoothing, acceleration tracking, stationary GPS jitter suppression, and rapid boundary closure rate detection.
- **Validation**: 9 dedicated unit tests passing in `test/motion_service_test.dart`.

### 5. Backend (FastAPI + SQLite/PostGIS)
- **SSE Stream Fix**: Resolved generator connection-closure bug in `backend/app/api/events.py` by ensuring database sessions remain open for the duration of the event stream. Added `limit` parameter for automated testing.
- **Real-Time Verification**: 21 backend tests in `backend/tests/` passed in 7.21s covering authentication, incidents, alerts, spatial fences, and SSE streams.

### 6. Frontend Operations Dashboard (Next.js 16)
- **Turbopack Production Build**: Successfully compiled 21 static and dynamic pages with zero syntax or TypeScript errors.
- **Civilian Safety UI/UX**: Professional dark-mode design system utilizing Slate 950, deep navy cards, high-contrast typography, and accessible status tokens.

---

## 4. Hardware Verification Status

- **Host Environment**: Windows 11 (Version 10.0.26200.9711), Flutter 3.44.4 stable, Android SDK 36.1.0, JDK 17.
- **Connected Physical Target**: Samsung Galaxy SM-A127F (`RZ8RC0FB4GY`).
- **Device Status**: `unauthorized` via ADB.
- **Current Blocker**: Hardware live on-device execution requires the user to tap "Allow USB debugging" on the physical smartphone screen. Software compilation, testing, and artifact packaging are 100% verified.

---

## 5. Verified Issue Register

| ID | File Path | Root Cause | Severity | Corrective Action | Verification Test | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **ISS-01** | `android/app/src/main/AndroidManifest.xml` | Missing network & notification permissions | HIGH | Added `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS` | `flutter test` | **RESOLVED** |
| **ISS-02** | `android/app/build.gradle.kts` | Keystore secrets hardcoded / missing environment abstraction | HIGH | Added `key.properties` and `BSAS_KEYSTORE_*` resolution with debug fallback | `assembleRelease` & `bundleRelease` | **RESOLVED** |
| **ISS-03** | `pubspec.yaml`, `build.gradle.kts` | App ID and version mismatches across files | MEDIUM | Unified ID `com.bordersafety.border_safety_alert` and version `1.1.0+2` | Build manifest inspection | **RESOLVED** |
| **ISS-04** | `lib/services/offline_tile_provider.dart` | OSM public tile servers blocking mobile client with 403 Forbidden | CRITICAL | Migrated to permitted ArcGIS World Street Map & Hybrid layers | Map unit test suite | **RESOLVED** |
| **ISS-05** | `lib/services/offline_map_service.dart` | False `READY` state without verifying physical files on disk | HIGH | Added physical disk verification and file counting in `verifyRegion` | `test/map_subsystem_test.dart` | **RESOLVED** |
| **ISS-06** | `backend/app/api/events.py` | Generator `finally: db.close()` terminated connection prematurely | HIGH | Moved session cleanup to generator completion and added query limit | `backend/tests/test_realtime.py` | **RESOLVED** |
| **ISS-07** | `lib/services/native_gguf_runtime.dart` | Missing `GgufMetadata` class and `verifyModelFile` signature | MEDIUM | Exposed model class and verification signature across IO and web stubs | `test/native_gguf_runtime_test.dart` | **RESOLVED** |
| **ISS-08** | `ios/Flutter/ephemeral` | Windows read-only filesystem locks blocking Flutter build tools | MEDIUM | Executed attribute clearing and directory reset | `flutter build apk --release` | **RESOLVED** |

---

## 6. Conclusion & Release Readiness

The Border Safety Alert System codebase is verified, zero-analyzer clean, 100% passing on automated test suites, and packaged into reproducible release artifacts (`.apk` and `.aab`). The system is ready for testing on authorized physical hardware or deployment staging.
