# System Architecture & Technical Specification — Border Safety Alert System (BSAS)

**Target Ecosystem:** Android 7.0+ (API 24 to 35), ARM64-v8a / ARM32, FastAPI, Next.js 16  
**Latest Version:** v1.1.0 (Production Release)  
**Repository:** [jagetheswaren/Border-Safety-Alert-System](https://github.com/jagetheswaren/Border-Safety-Alert-System)  
**Last Updated:** September 23, 2026  

---

## 1. Complete End-to-End System Blueprint

```text
                     CIVILIAN FIELD OPERATOR
                                │
                                ▼
         ┌─────────────────────────────────────────────┐
         │       FLUTTER PRODUCTION ANDROID APP        │
         │ (All 15 Fully Navigable Functional Pages)   │
         └──────────────────────┬──────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
 ┌─────────────┐        ┌──────────────┐        ┌──────────────┐
 │  GPS / GNSS │        │ Offline Map  │        │ Local SQLite │
 │ Hardware Fix│        │ Tile Storage │        │ Persistence  │
 └──────┬──────┘        │(OSM/Esri Sat)│        └──────┬───────┘
        │               └──────────────┘               │
        ▼                                              │
 ┌─────────────┐                                       │
 │  Geofence   │                                       │
 │ Mathematics │ (Sub-meter Point-In-Polygon)          │
 └──────┬──────┘                                       │
        │                                              │
        ▼                                              │
 ┌─────────────┐                                       │
 │   Feature   │ (Velocity, Bearing Delta,             │
 │ Extraction  │  Distance-to-Boundary Sliding Window) │
 └──────┬──────┘                                       │
        │                                              │
        ▼                                              │
 ┌─────────────┐                                       │
 │   Scaler    │ (Robust Z-Score Normalization)        │
 └──────┬──────┘                                       │
        │                                              │
   ┌────┴──────────────┐                               │
   ▼                   ▼                               │
┌──────────────┐┌──────────────┐                       │
│  LSTM Neural ││Random Forest │                       │
│(TFLite 1x5x6)││Classifier(JSON)                      │
└──────┬───────┘└──────┬───────┘                       │
       │               │                               │
       └───────┬───────┘                               │
               ▼                                       │
      ┌─────────────────┐                              │
      │   Risk Engine   │ (Deterministic Safety Fusion)│
      └────────┬────────┘                              │
               │                                       │
               ▼                                       │
      ┌─────────────────┐                              │
      │  Alert Service  │◄─────────────────────────────┘
      └────────┬────────┘
               │
    ┌──────────┼──────────┬──────────┐
    ▼          ▼          ▼          ▼
┌────────┐┌────────┐┌────────┐┌─────────────┐
│ Acoustic││Tactile ││Android ││Android Post │
│ Sirens ││Haptics ││Voice TTS││Notifications│
└────────┘└────────┘└────────┘└─────────────┘

SERVER & DASHBOARD CO-ORDINATION:
Flutter Mobile ────(TLS 1.3 / HTTPS)────► FastAPI REST API ────► Server DB ────► Next.js Dashboard

GENERATIVE AI SUBSYSTEMS:
• ANDROID ON-DEVICE: AI Chat UI ──► LocalChatService ──► ModelManager ──► Qwen3-0.6B-Q4_0.gguf (llama.cpp)
• LAPTOP DEVELOPMENT: BSAS Flutter ──► Local AI Service ──► Ollama (127.0.0.1:11434) ──► GPU In-Memory Model
```

---

## 2. Mobile Page Map (All 15 Verified Screens)

1. **Splash (`SplashScreen`):** Animated radar shield logo reveal with hardware readiness check (GPS, Offline Storage, ML Engine).
2. **Onboarding (`OnboardingScreen`):** 3-slide interactive civilian education on perimeter awareness, zero-cloud processing, and emergency actions.
3. **Permissions (`PermissionSetupScreen`):** Live audit and user request flow for GNSS Location, Android System Notifications, and Battery Optimization.
4. **Home (`HomeScreen`):** Real-time safety status HUD, active sector Proximity, GNSS accuracy badge, and quick action cards.
5. **Safety Status (`SafetyScreen`):** Large visual status indicator (SAFE / CAUTION / WARNING / CRITICAL), ML confidence metric, and perimeter guidance.
6. **Live Map (`MapScreen`):** Full-screen interactive map with dynamic layer switcher (Standard OSM, Esri World Imagery Satellite, Offline Sector Cache), accuracy circle, and geofence overlays.
7. **Alerts (`AlertsScreen`):** Real-time chronological incident feed with delivery audit badges (Sound, Vibration, TTS, Notification) and tap-to-inspect.
8. **Alert Details (`AlertDetailsScreen`):** Comprehensive incident report showing exact coordinates, timestamp, distance, hardware dispatch audit, and escape guidance.
9. **Safe Route (`RouteScreen`):** Obstacle-avoidance A* pathfinding calculating exit corridors avoiding restricted boundary polygons.
10. **AI Assistant (`AiChatScreen`):** Streaming token UI powered by local Qwen3-0.6B / Ollama with read-only safety snapshot isolation.
11. **History (`HistoryScreen`):** SQLite-backed historical audit log with filtering (All, Critical, Warning, Unsynced) and one-tap purge.
12. **Settings (`SettingsScreen`):** Toggles for acoustic siren, haptic vibration, TTS voice, language selection, and navigation links.
13. **About (`AboutScreen`):** Complete build information, architecture breakdown, software licenses, and GitHub repository links.
14. **Privacy (`PrivacyScreen`):** Zero-cloud tracking policy, data minimization, and one-tap local cache/history purge.
15. **Help (`HelpScreen`):** Emergency protocols, severity tier explanation, troubleshooting guide, and civilian notices.

---

## 3. Geospatial & Machine Learning Specifications

### 3.1 Deterministic Geofencing
- **Mathematical Method:** Ray-casting algorithm for Point-in-Polygon (PIP) testing; Haversine & Cross-Track formulations for minimum distance to boundary segments.
- **Authority:** Authoritative over all statistical models and generative AI advisory text.

### 3.2 Machine Learning Invariants
- **LSTM Input Tensor:** `[1, 5, 6]` representing 5 historical time steps of 6 normalized features:
  1. `latitude`
  2. `longitude`
  3. `speed` (m/s)
  4. `bearing` (degrees)
  5. `distance_to_boundary` (meters)
  6. `bearing_difference` (degrees)
- **Scaler:** `assets/models/scaler_params.json` (Median and Interquartile Range parameters).
- **Random Forest:** `assets/models/phase7-rf-v1.json` evaluating trajectory curvature and deceleration markers.
