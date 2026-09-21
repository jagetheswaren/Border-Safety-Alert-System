# BSAS Phase 4 Functional System Inventory

## 1. Flutter Mobile Application (`lib/` & `test/`)
- **Location & Sensors**:
  - `lib/services/gps_service.dart`: Device location acquisition, permission management, location stream handling.
  - `lib/models/location_model.dart`: Lat/Lon, altitude, speed, bearing, accuracy data model.
- **Geofencing & Spatial Math**:
  - `lib/services/geofence_service.dart`: Point-in-polygon & haversine distance calculations.
  - `lib/models/boundary_model.dart` & `lib/services/boundary_database.dart`: SQLite boundary storage (`sqflite`).
- **Edge AI & Predictive Pipeline**:
  - `lib/services/ai_prediction_service.dart`: On-device inference loading TFLite LSTM & JSON Random Forest.
  - `lib/models/ai_prediction_result.dart`: Lat/Lon displacement & Risk class output (`LOW`, `MEDIUM`, `HIGH`).
- **Alert & Notification System**:
  - `lib/services/alert_service.dart`: Sound, vibration, voice, local notifications (`flutter_local_notifications`).
- **UI Components**:
  - `lib/views/home_view.dart`, `lib/views/map_view.dart`, `lib/views/settings_view.dart`, `lib/views/alerts_view.dart`.

---

## 2. Edge AI/ML Models (`ml/` & `assets/models/`)
- **LSTM Movement Model**: `assets/models/phase7-lstm-v1.tflite` (38.9 KB)
  - Input: `[1, 5, 6]` (5 timesteps $\times$ 6 normalized spatial/sensor features).
  - Output: `[1, 2]` (`d_lat`, `d_lon` displacement vector).
- **Random Forest Classifier**: `assets/models/phase7-rf-v1.json` (5.1 KB)
  - 10 decision trees (max depth 5) mapping speed, bearing, distance, bearing difference to Risk Class.
- **Scaler**: `assets/models/scaler_params.json` (362 B)
  - `StandardScaler` mean and scale values.
- **Training Pipeline**: `ml/scripts/generate_dataset.py`, `ml/scripts/train_models.py`.

---

## 3. FastAPI Backend (`backend/app/`)
- **Authentication**: `app/api/auth.py` (`/api/v1/auth/login`, `/me`).
- **Incidents API**: `app/api/incidents.py` (`GET /`, `GET /{id}`, `POST /`). Paginated with filters.
- **Alerts API**: `app/api/alerts.py` (`GET /`, `POST /`). Paginated with filters.
- **Zones API**: `app/api/zones.py` (`GET /`, `POST /`).
- **Events Polling API**: `app/api/events.py` (`GET /api/v1/events/poll?since=<timestamp>`).
- **Dashboard Stats**: `app/api/dashboard.py` (`GET /api/v1/dashboard/stats`).
- **Geofence Check**: `app/api/geofence.py` (`POST /api/v1/geofence/check`).
- **Database**: SQLite `backend/bsas.db`.

---

## 4. Next.js Web Frontend (`frontend/src/`)
- **Pages**:
  - `/login`: Form posting to `/api/v1/auth/login`.
  - `/dashboard`: Overview stats & operations timeline.
  - `/dashboard/map`: Interactive Leaflet map visualizing real zones, incidents, and alerts.
  - `/dashboard/incidents`: Filterable & paginated incident table.
  - `/dashboard/incidents/[id]`: Detailed incident view with AI summary.
  - `/dashboard/alerts`: Filterable & paginated alert list.
- **API Client**: `frontend/src/lib/api.ts` & `frontend/src/lib/types.ts`.
