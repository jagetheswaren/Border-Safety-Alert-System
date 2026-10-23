# Border Safety Alert System (BSAS)

[![BSAS Continuous Integration](https://github.com/jagetheswaren/Border-Safety-Alert-System/actions/workflows/ci.yml/badge.svg)](https://github.com/jagetheswaren/Border-Safety-Alert-System/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.44.4-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js-16.3-black?logo=next.js)](https://nextjs.org)
[![React 19](https://img.shields.io/badge/React-19.2-61DAFB?logo=react)](https://react.dev)
[![Tailwind CSS v4](https://img.shields.io/badge/Tailwind_CSS-v4-38B2AC?logo=tailwind-css)](https://tailwindcss.com)

An offline-first, location-aware civilian safety platform combining **GPS/GNSS acquisition**, **deterministic geofencing**, **on-device machine learning (LSTM & Random Forest)**, **multimodal alerts**, a **FastAPI backend**, and a **Next.js operations command platform** featuring Google Maps Platform integration, MapLibre GL offline fallback, and React Bits tactical motion design.

---

## 1. Project Overview

### What is BSAS?
**Border Safety & Alert System (BSAS)** is an integrated civilian-first situational awareness application. It evaluates a user's real-time position against configured safety zones and restricted boundaries, predicts trajectory risks using on-device machine learning, and dispatches immediate sensory alerts—operating reliably even without active cellular or internet connectivity.

```text
Location Acquisition → Geofence Evaluation → Trajectory ML Inference → Risk Engine → Multimodal Alert
```

### Core Problems Solved
1. **Spatial Uncertainty**: Civilians and field personnel near restricted zones often lack precise situational awareness regarding how close they are to restricted boundaries.
2. **Connectivity Vulnerability**: Conventional cloud-based safety systems fail when internet connectivity drops in remote or border regions. BSAS operates completely offline using local boundary datasets (`borders.geojson`, `zones.geojson`), local SQLite, and on-device machine learning.
3. **Delayed Warning**: BSAS coordinates Android notifications, auditory alarms, haptic vibration, and Text-to-Speech (TTS) immediately when risk thresholds are exceeded.
4. **Command & Field Synergy**: Field telemetry synchronizes seamlessly with the Next.js Command Operations Dashboard whenever connectivity is available.

---

## 2. System Architecture

```text
                                 GOOGLE MAPS PLATFORM
                       ┌───────────────────┬───────────────────┐
                       │                   │                   │
                  Maps JS API         Places API          Routes API
                       │                   │                   │
                       ├──────────── Street View ──────────────┤
                       │
                       ├──────────────── Traffic ──────────────┤
                       │
                       ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │             NEXT.JS COMMAND OPERATIONS PLATFORM                 │
    │                                                                 │
    │  • Google Maps Vector Basemap    • Place Autocomplete Search    │
    │  • A-to-B Route Planner          • Interactive 360° Street View │
    │  • Real-time Traffic Overlay     • Basemap Modes (Sat/Hyb/Terr) │
    │  • Authoritative GeoJSON Borders • Buffer Safety Zones          │
    │  • Real-Time Device Telemetry    • Incident & Alert Management  │
    │  • Offline MapLibre GL Fallback  • React Bits Motion System     │
    └────────────────────────────────┬────────────────────────────────┘
                                     │
                               HTTPS / JWT
                                     │
                                     ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                        FASTAPI BACKEND                          │
    │                                                                 │
    │  • Authentication (OAuth2/JWT)   • RBAC (Admin/Operator/User)   │
    │  • Device Ingestion & Telemetry  • Incident Management          │
    │  • Alert Dispatch & Audit Log    • Offline Queue Sync API       │
    │  • Authoritative Border GeoJSON  • Safety Zone Configurations   │
    └────────────────────────────────┬────────────────────────────────┘
                                     │
                                  DATABASE
                                     │
                                     ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                      FLUTTER MOBILE APP                         │
    │                                                                 │
    │  • Real Hardware GPS Stream      • Foreground/Background Track  │
    │  • Local SQLite Database         • Offline Event Sync Queue     │
    │  • Offline Map (flutter_map)     • Deterministic Geofence       │
    │  • LSTM Trajectory ML (TFLite)   • Random Forest Risk Model     │
    │  • Multimodal Alerts (TTS/Vibe)  • Local Conversational AI      │
    └─────────────────────────────────────────────────────────────────┘
```

---

## 3. Technology Stack

| Domain | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile App** | **Flutter 3.44.4 & Dart 3.12.2** | Cross-platform mobile UI, native hardware bindings |
| **Mobile OS** | **Android (SDK 34 / Android 14)** | Target field deployment platform |
| **Location** | **Geolocator (GPS/GNSS)** | Continuous latitude, longitude, accuracy, speed, bearing |
| **Local Database** | **SQLite (`sqflite`)** | Offline boundary storage, local audit event store, sync queue |
| **Mobile Mapping** | **`flutter_map`** | Offline map visualization & cached raster tiles |
| **Neural Network** | **TensorFlow Lite (`tflite_flutter`)** | On-device sequential trajectory prediction (`phase7-lstm-v1.tflite`) |
| **Classifier** | **Random Forest (JSON)** | Multi-tree risk category majority voting (`phase7-rf-v1.json`) |
| **Alert Engine** | **Android Notifications, Audio, Vibration, TTS** | Multichannel emergency user notification |
| **Backend REST API** | **FastAPI & Python 3.11+** | Server API, auth, event aggregation, operational data |
| **Database ORM** | **SQLAlchemy** | Relational database mapping with SQLite / PostgreSQL / PostGIS |
| **Authentication** | **OAuth2 & JWT (`python-jose`, `passlib`, `bcrypt`)** | Secure token authorization & password hashing |
| **Web Dashboard** | **Next.js 16.3.5 (Turbopack), React 19.2.8** | Next-generation operational command platform |
| **Web Styling** | **Tailwind CSS v4 & Tactical Tokens** | Dark tactical operational theme (`--bsas-bg: #090d16`) |
| **Motion System** | **React Bits & Custom Motion Architecture** | Tactical animations (Cubes, SpotlightCard, Magnet, Dock, PillNav) |
| **Web Mapping** | **Google Maps JS API (`@vis.gl/react-google-maps`)** | Vector basemap, Places autocomplete, Routes navigation, Street View |
| **Offline Web Map** | **MapLibre GL JS (`maplibre-gl`)** | High-performance offline vector/raster fallback |
| **Geospatial Math** | **Turf.js (`@turf/turf`)** | Geodesic minimum point-to-polygon/line distance calculations |

---

## 4. Operational Safety & Geofencing Pipeline

Safety decisions are calculated on-device without cloud dependency:

```text
GPS/GNSS Fix
     ↓
Accuracy Validation (Reject fixes > 25m threshold)
     ↓
Geodesic Distance Calculation (WGS84 Minimum Geodesic Distance)
     ↓
Safety Zone Classification:
  • CRITICAL:  Distance < 300 meters
  • WARNING:   Distance < 1000 meters
  • AWARENESS: Distance < 2000 meters
  • SAFE:      Distance ≥ 2000 meters
     ↓
On-Device Trajectory AI Inference:
  • LSTM TFLite Model: Evaluates 5 past timesteps → Predicts trajectory [Δlat, Δlon]
  • Random Forest Model: Majority voting on feature vector → Risk classification
     ↓
Risk Synthesis Engine (Rule Engine + AI Assessment + Movement Trend)
     ↓
Multimodal Emergency Alert Dispatch:
  • Visual Alert Banner (Color-coded tactical warning)
  • Text-to-Speech (TTS Voice: "Critical warning. You are approaching a monitored boundary.")
  • Haptic Hardware Vibration (Patterned pulses)
  • Priority Android Notification
     ↓
Event Persisted in Local SQLite → Reconnection Sync Queue
```

---

## 5. Web Command Platform Features & UI/UX

The Next.js web application has been redesigned as an operations platform adhering to the React Bits motion specification:

- **Tactical Dark Theme**: Built on custom semantic CSS variables (`--bsas-bg`, `--bsas-surface`, `--bsas-accent`, `--bsas-critical`, `--bsas-warning`, `--bsas-awareness`, `--bsas-safe`).
- **Tactical Motion Engine**:
  - `Cubes`: 2D canvas 3D isometric spatial grid for the secure login portal (zero Three.js overhead; pauses on window blur; respects `prefers-reduced-motion`).
  - `SpotlightCard`: Ambient cursor-tracking radial highlights for operational cards.
  - `SlideActionButton`: Horizontal fill slide effect on hover, smooth loading compression, and success morphing.
  - `Magnet`: Physics-based cursor attraction for critical CTAs.
  - `Dock`: Floating tactical map controls dock with micro-magnification on hover.
  - `PillNav`: Tactile sliding tab selectors for filter bars and basemap modes.
  - `ElectricBorder`: Dynamic rotating gradient glow reserved for critical high-priority alert cards.
  - `DecryptedText`: Tactical cyber-scramble character resolution for system headers.
  - `CountUp`: Smooth rolling digit animation for telemetry metrics.
- **Unified Navigation Shell (`AppShell`)**:
  - Collapsible tactical sidebar (250px → 72px) with aligned icons and tooltips.
  - Compact command header with page breadcrumbs, real-time subsystem status rail (● BACKEND ONLINE, ● GPS READY, ● AI READY, ● SYNC CURRENT), and global keyboard search palette (`Ctrl+K` / `Cmd+K`).
- **Complete Operational Pages**:
  - `/login`: Secure authentication portal with animated spatial background.
  - `/dashboard`: Tactical Operations Overview with Magic Bento layout, rolling telemetry metrics, live operations timeline, and system health status.
  - `/dashboard/map`: 90% dominant live operations viewport, floating search, Dock controls, A-to-B route planner, 360° Street View split-screen, and real-time device telemetry overlays.
  - `/dashboard/incidents`: Incident management with search, status pills, and detail drawer.
  - `/dashboard/incidents/[id]`: Granular incident audit view with WGS84 fix and threat analysis.
  - `/dashboard/alerts`: Live alert feed with acknowledge/resolve actions.
  - `/dashboard/devices`: Field telemetry tracking with speed, bearing, and accuracy indicators.
  - `/dashboard/zones`: Centrally configured safety zone thresholds (300m / 1000m / 2000m).
  - `/dashboard/events`: Chronological system audit and telemetry log.
  - `/dashboard/sync`: Offline SQLite event reconciliation and manual sync trigger.
  - `/dashboard/health`: Real-time system health diagnostic matrix.
  - `/dashboard/settings`: Operator preferences, refresh cadence, and accessibility toggles.

---

## 6. Setup & Installation

### Prerequisites
- **Flutter SDK**: 3.44.4+
- **Dart SDK**: 3.12.2+
- **Android Studio / Android SDK**: Platform 34+
- **Python**: 3.11+
- **Node.js**: 20+

### 1. Backend API (FastAPI)
```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1   # On Windows (or source venv/bin/activate on Unix)

# Install dependencies
pip install -r requirements.txt

# Seed database with administrative accounts, boundaries, and initial incidents
python seed.py

# Run complete pytest test suite (17/17 tests passing)
pytest tests -v

# Start development API server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Frontend Command Dashboard (Next.js)
```bash
cd frontend

# Install dependencies
npm install

# Run ESLint validation (0 errors, 0 warnings)
npm run lint

# Build production bundle with Next.js Turbopack
npm run build

# Start production server (or npm run dev for development)
npm run start
```

### 3. Mobile Application (Flutter)
```powershell
# Fetch dependencies
flutter pub get

# Run static analysis (0 issues found)
dart analyze

# Run complete test suite (116/116 tests passing)
flutter test

# Run application on connected physical device or emulator
flutter run
```

---

## 7. Google Maps Platform Setup

For live Google Maps basemaps, Place autocomplete, Routes navigation, and Street View 360° panoramas:

1. Refer to [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) for full setup instructions.
2. Configure `frontend/.env.local`:
   ```bash
   NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=YOUR_RESTRICTED_GOOGLE_MAPS_API_KEY
   NEXT_PUBLIC_GOOGLE_MAP_ID=YOUR_VECTOR_MAP_ID
   NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
   ```
3. *Note*: If no API key is provided, BSAS automatically falls back to the **MapLibre GL JS** offline engine without application crashes.

---

## 8. Verification & Quality Assurance Reports

For exhaustive verification results, architecture audits, and testing evidence:
- **Final Verification Report**: [FINAL_BSAS_VERIFICATION_REPORT.md](FINAL_BSAS_VERIFICATION_REPORT.md)
- **UI/UX Rebuild Report**: [UI_UX_REBUILD_REPORT.md](UI_UX_REBUILD_REPORT.md)
- **Google Maps Configuration Guide**: [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md)
- **Audit & Gap Analysis**: [AUDIT_AND_GAP_ANALYSIS.md](AUDIT_AND_GAP_ANALYSIS.md)

---

## 9. Security & Hardening

- **Cryptographic Hashing**: Passwords stored using `bcrypt` via Passlib.
- **JWT Authorization**: Authenticated API endpoints validate OAuth2 Bearer JSON Web Tokens.
- **Production Fail-Safe**: Backend refuses to start in `production` mode if weak development secrets are detected.
- **Client Key Security**: Google Maps API keys are restricted via HTTP referrers (`http://localhost:3000/*`) and API service restrictions.
- **Data Privacy & Ingestion Validation**: Telemetry ingestion validates coordinates (WGS84 boundaries), rejects out-of-order timestamps, and strips sensitive data for non-privileged roles.

---

## 10. License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
