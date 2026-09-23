# Border Safety Alert System (BSAS)

[![BSAS Continuous Integration](https://github.com/jagetheswaren/Border-Safety-Alert-System/actions/workflows/ci.yml/badge.svg)](https://github.com/jagetheswaren/Border-Safety-Alert-System/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.4-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js-16.3-black?logo=next.js)](https://nextjs.org)

An offline-first, location-aware civilian safety platform combining **GPS/GNSS acquisition**, **deterministic geofencing**, **on-device machine learning (LSTM & Random Forest)**, **multimodal alerts**, a **FastAPI backend**, a **Next.js operations dashboard**, and an **advisory local AI assistant**.

---

## 1. Project Overview

### What is BSAS?
**Border Safety Alert System (BSAS)** is a civilian-first situational awareness application. It evaluates a user's real-time position against configured safety zones and restricted boundaries, predicts trajectory risks using on-device machine learning, and dispatches immediate sensory alerts—operating reliably even without active cellular or internet connectivity.

> **Location Acquisition → Geofence Evaluation → Trajectory ML Inference → Risk Engine → Multimodal Alert**

### Core Problems Solved
1. **Spatial Uncertainty**: Civilians travelling near restricted zones often lack precise situational awareness regarding how close they are to restricted boundaries.
2. **Connectivity Vulnerability**: Conventional cloud-based safety systems fail when internet connectivity drops in remote or border regions. BSAS operates offline using local boundary databases and on-device machine learning.
3. **Delayed Warning**: BSAS coordinates Android notifications, auditory alarms, haptic vibration, and Text-to-Speech (TTS) immediately when risk thresholds are exceeded.

---

## 2. Complete System Architecture

```text
                               ┌─────────────────────────┐
                               │         USER            │
                               │   Android Smartphone    │
                               └────────────┬────────────┘
                                            │
                                            ▼
                          ┌───────────────────────────────────┐
                          │        FLUTTER MOBILE APP         │
                          │   Home / Safety / Map / Alerts    │
                          │        Route / AI / Settings      │
                          └─────────────────┬─────────────────┘
                                            │
                 ┌──────────────────────────┼──────────────────────────┐
                 │                          │                          │
                 ▼                          ▼                          ▼
          ┌─────────────┐            ┌──────────────┐           ┌──────────────┐
          │  GPS / GNSS │            │ Offline Map  │           │ Local SQLite │
          │ Coordinates │            │ Tile Storage │           │ Event Store  │
          └──────┬──────┘            └──────────────┘           └──────┬───────┘
                 │                                                     │
                 ▼                                                     │
          ┌─────────────┐                                              │
          │  Geofence   │                                              │
          │   Engine    │                                              │
          └──────┬──────┘                                              │
                 │                                                     │
                 ▼                                                     │
          ┌─────────────┐                                              │
          │   Feature   │                                              │
          │ Extraction  │                                              │
          └──────┬──────┘                                              │
                 │                                                     │
                 ▼                                                     │
          ┌─────────────┐                                              │
          │ Z-Score     │                                              │
          │ Scaler      │                                              │
          └──────┬──────┘                                              │
                 │                                                     │
          ┌──────┴──────┐                                              │
          ▼             ▼                                              │
     ┌─────────┐   ┌─────────────┐                                     │
     │  LSTM   │   │Random Forest│                                     │
     │ TFLite  │   │ Model (JSON)│                                     │
     └────┬────┘   └──────┬──────┘                                     │
          │               │                                            │
          └───────┬───────┘                                            │
                  ▼                                                    │
            ┌─────────────┐                                            │
            │ Risk Engine │◄───────────────────────────────────────────┘
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │Alert Service│
            └──────┬──────┘
                   │
       ┌───────────┼───────────┐
       ▼           ▼           ▼
  Notification   Sound     Vibration
                   │
                   ▼
              Text-to-Speech
                   │
                   ▼
                 USER


            SERVER & OPERATIONS PIPELINE (HTTPS / REST)
            ───────────────────────────────────────────

                          Flutter Mobile App
                                  │
                                  │ HTTPS / REST API
                                  ▼
                          ┌───────────────┐
                          │    FastAPI    │
                          │    Backend    │
                          └───────┬───────┘
                                  │
                   ┌──────────────┼──────────────┐
                   ▼              ▼              ▼
               Auth API       Events API     Alerts API
                   │              │              │
                   └──────────────┼──────────────┘
                                  ▼
                          ┌───────────────┐
                          │   Database    │
                          │   (SQLite)    │
                          └───────┬───────┘
                                  │
                                  ▼
                          ┌───────────────┐
                          │    Next.js    │
                          │ Web Dashboard │
                          └───────────────┘
```

---

## 3. Technology Stack

| Domain | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile App** | **Flutter & Dart** | Cross-platform UI, native hardware bindings |
| **Operating System** | **Android** (SDK 34) | Target mobile deployment platform |
| **Location** | **Geolocator** (GPS/GNSS) | Continuous latitude, longitude, accuracy, speed, bearing |
| **Local Database** | **SQLite (`sqflite`)** | Offline boundary storage, local audit event store |
| **Mapping** | **`flutter_map`** | Offline map visualization & cached raster tiles |
| **Neural Network** | **TensorFlow Lite (`tflite_flutter`)** | On-device sequential trajectory prediction (`phase7-lstm-v1.tflite`) |
| **Classifier** | **Random Forest (JSON)** | Multi-tree risk category majority voting (`phase7-rf-v1.json`) |
| **Alert Engine** | **Android Notifications, Audio, Vibration, TTS** | Multichannel emergency user notification |
| **Backend REST API** | **FastAPI & Python 3.11** | Server API, auth, event aggregation, operational data |
| **Database ORM** | **SQLAlchemy** | Relational database mapping with SQLite / PostgreSQL |
| **Authentication** | **OAuth2 & JWT (`python-jose`, `passlib`, `bcrypt`)** | Secure token authorization & password hashing |
| **Web Dashboard** | **Next.js 16, TypeScript, Tailwind CSS** | Operations portal, Leaflet live map, incidents monitoring |
| **Local AI (Advisory)** | **Qwen3-0.6B GGUF** | Offline conversational field safety assistant |

---

## 4. Machine Learning & Risk Pipeline

The application features on-device machine learning with zero server dependency for safety decisions:

```text
Location History (5 timesteps)
             ↓
    Feature Extraction:
    [lat, lon, speed, bearing, distance_to_boundary, bearing_diff]
             ↓
    Z-score Normalization (scaler_params.json)
             ↓
     ┌───────┴───────┐
     ▼               ▼
LSTM (TFLite)    Random Forest (JSON)
Shape: [1,5,6]   Majority Voting
Outputs: [Δlat, Δlon]  Outputs: Risk Class (0: Low, 1: Med, 2: High)
     │               │
     └───────┬───────┘
             ▼
        Risk Engine
             ↓
    Authoritative Decision (SAFE / CAUTION / WARNING / CRITICAL)
```

### Verified Model Artifacts
- **LSTM TFLite**: `assets/models/phase7-lstm-v1.tflite` (38,992 bytes, SHA-256: `84A147F1D7F19248DE41DAE23FB07094D4AB5DE4FC5FB2DE951914133E8DE51E`)
- **Random Forest**: `assets/models/phase7-rf-v1.json` (5,148 bytes, SHA-256: `33FE1BC987A58C2B61CEE0A17A07D85B9D4232157D02B2E4A863822946EAA0BE`)
- **Scaler Parameters**: `assets/models/scaler_params.json` (362 bytes, SHA-256: `044FED0634B134739402E9DB2DA768BB0CCDC83ADB12C033F65FC099B69C5A16`)

---

## 5. Local Conversational AI & Safety Isolation

BSAS integrates an on-device local assistant architecture using **Qwen3-0.6B Q4_0 GGUF**.

```text
Safety Context Snapshot (GPS, Risk State, Alerts)
                        │ [READ-ONLY]
                        ▼
               LocalChatService
                        │
                        ▼
                  ModelManager
                        │
                        ▼
                GGUF Runtime Engine
                        │
                        ▼
               Qwen3-0.6B-Q4_0.gguf
                        │
                        ▼
                Advisory Streamed Tokens
```

### Architectural Safety Isolation Invariant
- **Advisory Role Only**: The local AI operates strictly on a read-only snapshot of the safety context.
- **Zero Mutability**: The AI assistant cannot modify GPS readings, disable alarms, change risk state, or alter boundary definitions.
- **Deterministic Priority**: The deterministic geofence and ML risk engine remain the sole authority for safety-critical decisions.

---

## 6. Repository Layout

```text
.
├── android/                 Native Android application and Gradle configuration
├── assets/
│   ├── audio/               Warning sirens and notification chimes
│   ├── boundaries/          Bundled demo GeoJSON safety polygons
│   ├── branding/            Logos, app icons, and branding assets
│   ├── maps/                Offline map metadata and local tile storage
│   └── models/              Real on-device ML models (LSTM TFLite, RF JSON, Scaler)
├── backend/                 FastAPI backend application
│   ├── app/                 Routes (/auth, /users, /zones, /incidents, /alerts, /dashboard)
│   ├── tests/               Pytest test suite
│   └── requirements.txt     Backend Python dependencies
├── docs/                    Comprehensive architecture & engineering documentation
│   └── ARCHITECTURE.md      Detailed system architecture & sequence blueprints
├── frontend/                Next.js web operations dashboard
│   ├── src/app/             Dashboard routes (/dashboard, /incidents, /alerts, /map, /login)
│   ├── package.json         Frontend dependencies (Next.js 16, React 19, Leaflet)
│   └── tsconfig.json        TypeScript configuration
├── lib/                     Flutter mobile application source code
│   ├── core/                Design system, theme tokens, and shared UI widgets
│   ├── database/            Local SQLite database (AppDatabase)
│   ├── models/              Location, safety state, geofence, and alert data models
│   ├── screens/             Mobile screens (Home, Map, Safety, Alerts, Route, AI, Settings)
│   └── services/            GPS, Geofence, RiskEngine, ML, Alerts, LocalChat, Sync services
├── test/                    Flutter unit and widget test suite (96 tests)
└── .github/workflows/ci.yml GitHub Actions continuous integration pipeline
```

---

## 7. Setup & Installation

### Prerequisites
- **Flutter SDK**: 3.44.4+
- **Dart SDK**: 3.12.2+
- **Android Studio / Android SDK**: Platform 34+
- **Python**: 3.10+
- **Node.js**: 20+

### 1. Mobile Application (Flutter)
```powershell
# Fetch dependencies
flutter pub get

# Run static analysis
flutter analyze lib/

# Run complete test suite (96 tests)
flutter test
```

### 2. Backend API (FastAPI)
```powershell
# Navigate to backend directory or use virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1   # On Windows (or source venv/bin/activate on Unix)

# Install dependencies
pip install -r backend/requirements.txt

# Run backend test suite
pytest backend/tests -v

# Start development API server
uvicorn app.main:app --reload --port 8000
```

### 3. Web Dashboard (Next.js)
```bash
cd frontend
npm install
npm run lint
npm run build
npm run dev
```

---

## 8. Android Production Release Build

To build the signed/release Android application package:

```powershell
flutter build apk --release
```

The release APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 9. Security & Hardening

- **Cryptographic Hashing**: Passwords stored using `bcrypt` via Passlib.
- **JWT Authorization**: Authenticated API endpoints validate OAuth2 Bearer JSON Web Tokens.
- **Production Fail-Safe**: Backend refuses to start in `production` mode if weak development secrets are detected.
- **Data Privacy**: Location data remains local to the device during offline mode; sync occurs only through authenticated API endpoints over HTTPS.

---

## 10. License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
