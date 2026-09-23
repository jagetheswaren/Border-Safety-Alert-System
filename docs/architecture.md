# Border Safety Alert System (BSAS) — System Architecture

This document specifies the technical architecture, data pipelines, module interactions, and safety isolation invariants of the **Border Safety Alert System (BSAS)**.

---

## 1. High-Level Architecture Blueprint

```text
                               ┌─────────────────────────┐
                               │         USER            │
                               │   Android Smartphone    │
                               └────────────┬────────────┘
                                            │
                                            ▼
                          ┌───────────────────────────────────┐
                          │        FLUTTER MOBILE APP         │
                          │            (Dart / UI)            │
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


                   LOCAL CONVERSATIONAL AI PIPELINE
                   ────────────────────────────────

                      Safety Context Snapshot
                      (GPS, Risk, Alerts, Mode)
                                  │ [READ-ONLY]
                                  ▼
                         ┌─────────────────┐
                         │ LocalChatService│
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  ModelManager   │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │  GGUF Runtime   │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   Qwen3 0.6B    │
                         │    Q4_0 GGUF    │
                         └────────┬────────┘
                                  │
                                  ▼
                         Advisory AI Response
                         (Streamed to Chat UI)
```

---

## 2. Core Operational Pipelines

### Pipeline 1: On-Device Safety & Alert Pipeline (Authoritative)

The safety pipeline executes 100% on the mobile device and does not depend on cloud connectivity.

1. **GNSS Location Acquisition**: The device acquires satellite readings via `GpsService`, recording `latitude`, `longitude`, `accuracy`, `speed`, and `bearing`.
2. **Geofence Evaluation**: The coordinates are compared against active boundary polygons stored in the local SQLite database (`AppDatabase` / `BoundaryRepository`) using ray-casting point-in-polygon and Haversine minimum distance algorithms.
3. **Feature Construction**: A 5-step rolling trajectory window is constructed:
   $$\mathbf{X} = [\text{lat}, \text{lon}, \text{speed}, \text{bearing}, \text{distance\_to\_boundary}, \text{bearing\_diff}]$$
4. **Feature Normalization**: Features are scaled using parameters from `scaler_params.json` ($z = \frac{x - \mu}{\sigma}$).
5. **Machine Learning Inference**:
   - **LSTM (`phase7-lstm-v1.tflite`)**: Input shape `[1, 5, 6]`, outputs predicted coordinate displacement $[\Delta\text{lat}, \Delta\text{lon}]$.
   - **Random Forest (`phase7-rf-v1.json`)**: Majority voting across decision trees classifies risk level (`low`, `medium`, `high`).
6. **Risk Engine Fusion**: `RiskEngine` fuses deterministic geofence state (`SAFE`, `CAUTION`, `WARNING`, `CRITICAL`) with ML inferences. Deterministic boundary violation always supersedes ML predictions.
7. **Event-Driven Alert Dispatch**: `AlertService` triggers the configured alert channels:
   - System notification (`NotificationService`)
   - Audible warning tones (`SoundService`)
   - Haptic vibration patterns (`VibrationAlertService`)
   - Voice announcements (`VoiceAlertService` / TTS)

### Pipeline 2: Server & Operations Sync Pipeline

When network connectivity is present, the application synchronizes with the operations infrastructure:

1. **REST Client (`Flutter`)**: Sends background event logs and incident reports to the FastAPI backend.
2. **FastAPI Backend**:
   - Validates requests via Pydantic schemas.
   - Enforces authentication with OAuth2 Bearer tokens signed via JWT (`HS256`).
   - Persists data to the backend relational database (`SQLAlchemy`).
3. **Next.js Web Dashboard**:
   - Consumes backend endpoints (`/api/v1/dashboard/stats`, `/api/v1/incidents`, `/api/v1/alerts`).
   - Renders live incident locations on Leaflet maps, tabular logs, and system metrics.

### Pipeline 3: Local Conversational AI Pipeline (Advisory Only)

The local AI assistant provides conversational explanation and diagnostics directly on-device:

1. **Context Snapshot**: A read-only snapshot of current safety conditions (`latitude`, `longitude`, `accuracy`, `zoneState`, `riskState`, `activeAlertCount`) is passed to `LocalChatService`.
2. **Model Lifecycle**: `ModelManager` verifies model presence (`models/qwen/Qwen3-0.6B-Q4_0.gguf`), validates file integrity against SHA-256 (`DA2572F16C06133561CE56ACCAA822216F2391EF4D37FBA427801CD6736417D4`), and manages on-device loading.
3. **Inference Execution**: Uses a local GGUF runtime to generate explanatory tokens without cloud API access.

---

## 3. Strict Safety Isolation Invariant

An essential architectural invariant of BSAS is the **unidirectional decoupling** between the safety engine and the conversational AI assistant:

```text
┌──────────────────────────────────────────────────────────┐
│          DETERMINISTIC SAFETY & ML PIPELINE              │
│       GPS → Geofence → LSTM/RF → RiskEngine → Alerts     │
└────────────────────────────┬─────────────────────────────┘
                             │
                             │ Read-Only Context Snapshot
                             ▼
┌──────────────────────────────────────────────────────────┐
│            ADVISORY CONVERSATIONAL ASSISTANT             │
│            LocalChatService (Qwen3 0.6B GGUF)            │
└──────────────────────────────────────────────────────────┘
```

- **Read-Only Context**: The conversational AI receives an immutable snapshot of safety states.
- **Zero Control Authority**: The AI has no execution hooks or API paths to alter GPS fixes, redefine geofence zones, suppress alarms, or modify the application risk state.
- **Safety Precedence**: Deterministic boundary rules always govern civilian safety alerts.

---

## 4. Component Mapping

| Subsystem | Input | Processing | Output | Implementation File |
| :--- | :--- | :--- | :--- | :--- |
| **GPS Acquisition** | Satellite GNSS signals | Hardware location stream filtering | `LocationModel` (lat, lon, accuracy, speed, bearing) | `lib/services/gps_service.dart` |
| **Geofencing** | `LocationModel` + boundary polygons | Point-in-polygon & Haversine distance | `GeoFenceResult` (zone, distance, state) | `lib/services/geofence_service.dart` |
| **Local Boundary DB** | Bundled GeoJSON / SQL seeds | SQLite persistence & spatial indexing | Stored boundary geometries | `lib/services/boundary_repository.dart` |
| **Feature Scaling** | 6-feature trajectory window | Z-score normalization | Scaled feature vector | `lib/services/ai_prediction_service.dart` |
| **LSTM Prediction** | Tensor `[1, 5, 6]` | Sequential neural inference | Next coordinate displacement `[1, 2]` | `assets/models/phase7-lstm-v1.tflite` |
| **Random Forest** | Scaled features `[4]` | Decision tree ensemble voting | Risk class (`low`, `medium`, `high`) | `assets/models/phase7-rf-v1.json` |
| **Risk Engine** | Geofence state + ML output | Weighted rule fusion | Final `SafetyState` | `lib/services/risk_engine.dart` |
| **Alert Service** | Risk change event | Cooldown & channel orchestration | Dispatch triggers | `lib/services/alert_service.dart` |
| **Android Alerts** | Alert triggers | Native platform channels | Notifications, Audio, Vibration, TTS | `lib/services/*_alert_service.dart` |
| **Offline Map** | Local cached map tiles + GPS | Vector/raster rendering | Interactive map UI | `lib/services/offline_map_service.dart` |
| **Local AI Manager** | GGUF model binary | File integrity & checksum validation | Model ready / loaded state | `lib/services/model_manager.dart` |
| **Local Chat** | User prompt + safety snapshot | Streaming inference token generation | Text advice response | `lib/services/local_chat_service.dart` |
| **Backend API** | HTTP requests (JSON/Form) | Authentication, validation, DB query | JSON API responses | `backend/app/main.py` |
| **Web Dashboard** | Backend JSON endpoints | React/Next.js dashboard rendering | Operations UI | `frontend/src/app/dashboard/` |
