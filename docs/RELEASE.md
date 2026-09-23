# Release Guide & Version Matrix — Border Safety Alert System (BSAS)

**Latest Stable Release:** v1.1.0  
**Build Date:** September 23, 2026  
**Artifacts Available:**
- Sideloadable Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Google Play App Bundle (AAB): `build/app/outputs/bundle/release/app-release.aab`

---

## 1. Versioning Specification

BSAS follows Semantic Versioning (SemVer 2.0.0):
- **MAJOR:** Architectural paradigm shifts or breaking safety protocol revisions.
- **MINOR:** New functional features (e.g., Satellite layer integration, local Generative AI runtime, new boundary import formats).
- **PATCH:** Bug fixes, performance optimizations, and security patches.

---

## 2. Build Pipeline & Commands

### 2.1 Compiling the Sideloadable Release APK
```bash
# Build universal release APK
flutter build apk --release --no-pub

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### 2.2 Compiling the Google Play App Bundle (AAB)
```bash
# Build optimized split-delivery App Bundle
flutter build appbundle --release --no-pub

# Output location:
# build/app/outputs/bundle/release/app-release.aab
```

### 2.3 Verification Commands
```bash
# Compute SHA-256 Checksum on Windows PowerShell
Get-FileHash -Algorithm SHA256 build\app\outputs\flutter-apk\app-release.apk
Get-FileHash -Algorithm SHA256 build\app\outputs\bundle\release\app-release.aab

# Verify APK signing and alignment
$env:ANDROID_HOME\build-tools\34.0.0\apksigner.bat verify --verbose build\app\outputs\flutter-apk\app-release.apk
```

---

## 3. Physical Hardware Installation

To install the verified release APK directly onto a connected physical Android device:
```bash
# Verify ADB connection
adb devices

# Sideload with permission grant
adb install -r -g build/app/outputs/flutter-apk/app-release.apk

# Launch BSAS application
adb shell monkey -p org.bsas.bordersafety -c android.intent.category.LAUNCHER 1
```

---

## 4. Release History & Changelog

### Version 1.1.0 (2026-09-23) — Production Release
- **All 15 Application Pages Implemented:** Splash, Onboarding, Permissions, Home, Safety Status, Live Map, Alerts, Alert Details, Safe Route, AI Assistant, History, Settings, About, Privacy, Help.
- **Satellite Map Support:** Added Esri World Imagery high-resolution global satellite photography layer with dynamic layer switcher (Standard / Satellite / Offline Sector).
- **Offline Map Pre-Caching:** Added sector pre-caching workflow for Pollachi/Coimbatore corridor with live progress and storage metrics.
- **Original Vector Brand Identity:** Reusable animated radar shield vector icon (`BsasLogo`) across splash, home, map, and launcher icons.
- **Physical Device Validation:** Verified on Samsung Galaxy A12s (SM-A127F, Android 13) with native TFLite LSTM runtime initialization and Android TTS binding.
- **Google Play Store Preparation:** App bundle (`app-release.aab`) compiled, store metadata, screenshots, and privacy policies drafted.
