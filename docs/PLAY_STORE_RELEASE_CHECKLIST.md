# Google Play Store Release Checklist — Border Safety Alert System (BSAS)

**Target Release:** v1.1.0 (Production Release)  
**Package Name:** `org.bsas.bordersafety`  
**Application Title:** Border Safety Alert System  
**Category:** Safety / Navigation / Tools  
**Content Rating:** Everyone (PEGI 3 / ESRB Everyone)  
**Document Generated:** 2026-09-23  

---

## 1. Technical Manifest & Build Artifacts

| Parameter | Specification | Verification Status |
| :--- | :--- | :--- |
| **Application ID** | `org.bsas.bordersafety` | **PASS** — Verified in `android/app/build.gradle.kts` |
| **Version Name** | `1.1.0` | **PASS** — Bumped from `1.0.0` for production release |
| **Version Code** | `2` | **PASS** — Sequential integer for Play Console tracks |
| **Minimum SDK** | API 24 (Android 7.0 Nougat) | **PASS** — Covers >95% active global devices |
| **Target SDK** | API 34 (Android 14) | **PASS** — Meets Google Play 2026 Target API mandate |
| **Compile SDK** | API 35 (Android 15) | **PASS** — Latest toolchain compatibility |
| **Architecture** | `arm64-v8a`, `armeabi-v7a` | **PASS** — 64-bit compliant release |
| **App Bundle (.aab)** | `build/app/outputs/bundle/release/app-release.aab` | **VERIFIED** — Optimized split delivery for Play Store |
| **Testing APK (.apk)** | `build/app/outputs/flutter-apk/app-release.apk` | **VERIFIED** — Sideloadable release test build (72.0 MB) |
| **Code Shrinking & Obfuscation** | R8 / ProGuard enabled | **PASS** — Obfuscates proprietary ML & risk engine logic |

---

## 2. Store Listing Assets & Metadata

### 2.1 Store Copy
- **App Name (Title):** `Border Safety Alert System` (28 chars, max 30)
- **Short Description:** `Real-time offline border safety, GNSS geofencing, ML risk alerts & AI guidance.` (79 chars, max 80)
- **Full Description:**
```text
The Border Safety Alert System (BSAS) is an offline-first civilian perimeter awareness application engineered to prevent unintentional boundary crossings into restricted buffer zones and sensitive international or state corridors.

KEY HIGHLIGHTS:
• DETERMINISTIC GNSS GEOFENCING: Sub-meter point-in-polygon mathematics continuously evaluate your live coordinates against authorized civilian boundary polygons.
• ZERO CLOUD TELEMETRY: All geospatial positioning, ML inference, and alert evaluations occur 100% on your local device. Your coordinates are never uploaded, sold, or shared.
• ON-DEVICE MACHINE LEARNING: Bundled TensorFlow Lite LSTM neural network and Random Forest classifier analyze velocity, trajectory bearing, and distance deltas to project border breach probability.
• MULTI-MODAL EMERGENCY DISPATCH: Calibrated acoustic sirens, high-priority system notifications, tactile vibration pulses, and native spoken Voice (TTS) guidance.
• OFFLINE SECTOR MAPPING: Pre-cached vector and raster maps with high-resolution satellite imagery support (Esri World Imagery) operate seamlessly with zero mobile data.
• LOCAL GENERATIVE AI: Read-only Qwen3-0.6B local language model provides contextual terrain analysis and safe transit protocols without needing an internet connection.
• EMERGENCY ESCAPE ROUTING: Built-in obstacle-avoidance A* pathfinding calculates a safe egress corridor away from restricted zones.

BSAS is an assistive civilian safety tool. Always adhere to official border signage and directives from law enforcement personnel.
```

### 2.2 Visual Brand Assets
- [x] **App Icon:** 512x512 PNG, 32-bit color, no alpha channel (`assets/branding/bsas_logo.png`).
- [x] **Adaptive Launcher Icon:** Foreground vector shield + radar pin with solid background (`android/app/src/main/res/mipmap-hdpi/ic_launcher.png`).
- [x] **Feature Graphic:** 1024x500 PNG depicting radar perimeter monitoring and satellite safety HUD.
- [x] **Phone Screenshots:** Minimum 4 high-resolution (1080x2400) screenshots:
  1. Home Screen (Safe Status HUD & Live Telemetry)
  2. Live Map (Standard & Satellite Imagery with Geofence Polygons)
  3. Alert Incident Report (Multi-modal dispatch audit & actions)
  4. Local AI Assistant (Streaming Qwen3 safety advisory)
  5. Safe Escape Route (A* pathfinding avoiding restricted sectors)

---

## 3. Privacy, Data Safety & Permissions

### 3.1 Permissions Audit (`AndroidManifest.xml`)
- `android.permission.ACCESS_FINE_LOCATION`: Required for life-safety geofence distance calculation.
- `android.permission.ACCESS_COARSE_LOCATION`: Fallback network-based fix.
- `android.permission.POST_NOTIFICATIONS`: Android 13+ critical alert notification posting.
- `android.permission.VIBRATE`: Tactile alerting for sensory alert redundancy.
- `android.permission.INTERNET`: Tile cache download & self-hosted backend sync (optional).

### 3.2 Google Play Data Safety Declarations
- **Data Collection:**
  - **Location (Precise):** Yes, collected on-device for safety functionality. **Not shared with third parties. Ephemeral processing.**
  - **Diagnostics & App Activity:** Local crash logs only. **Not shared.**
- **Security Practices:**
  - Data encrypted in transit (TLS 1.3) when syncing with self-hosted server.
  - Data stored in private Android app sandbox (SQLite).
  - Users can purge all cached tiles, trip histories, and database logs with one tap.

---

## 4. Release Signing & Credentials

- [x] Production Keystore: Configured in `android/app/build.gradle.kts` (or Google Play App Signing key management).
- [x] SHA-256 Fingerprint recorded for API integrity & Play Integrity API.
- [x] Clean environment: No debug tokens, no hardcoded API secrets, `.env` excluded from VCS.

---

## 5. Play Console Pre-Launch Verification

- [x] Internal Testing Track uploaded
- [x] Pre-launch report reviewed for ANR / Crash issues across ARM64 & ARM32 devices
- [x] Target SDK 34 policy compliance verified
- [x] Content Rating questionnaire completed (Rating: Everyone)
- [x] Privacy Policy URL linked: `https://github.com/jagetheswaren/Border-Safety-Alert-System/blob/main/docs/PRIVACY.md`
