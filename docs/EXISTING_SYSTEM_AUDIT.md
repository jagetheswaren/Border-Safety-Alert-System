# Existing System Audit: Border Safety Alert System (BSAS)

## What Exists
Based on the repository structure and documentation:
1. **Flutter Mobile Application**: Located in the root (`lib/`, `android/`, `ios/`, etc.). It includes offline functionality, a GPS service, offline boundary SQLite database, deterministic geo-fencing, and visual/voice/vibration/notification alerts.
2. **Machine Learning Pipeline (Stub)**: A `ml/` directory exists with scaffolding for datasets, preprocessing, training, and models, but no trained models or mobile inference integration is present.
3. **Backend Service (Stub)**: A `backend/` directory exists containing a basic FastAPI stub, but it is currently not required by the core app.
4. **Boundary Data**: A `boundary-data/` directory contains synthetic demo JSON/SQLite data.
5. **Documentation**: Detailed design plans (Phases 1-8 audits, architecture, AI pipeline, geofencing, etc.) inside `docs/`.

## What Works
- The Flutter application successfully builds and runs.
- The offline safety engine works deterministically using foreground GPS fixes and locally seeded boundaries.
- Alerts (visual, voice, vibration, notifications) trigger properly based on the geofence logic.
- The existing codebase is fully analyzed (`flutter analyze` returns 0 issues) and has passing tests.

## What Is Missing
- **Centralized Platform**: A comprehensive FastAPI backend with PostgreSQL/PostGIS and Redis.
- **Web Dashboard**: A full Next.js control center for operators with real-time maps, incident management, and analytics.
- **Authentication & RBAC**: Real user management and permissioning on the backend.
- **Real-time WebSockets**: Live event propagation between devices, backend, and dashboard.
- **AI Integration (Server/Local)**: Currently only stubs; needs LLM integration for incident analysis and the actual implementation of the LSTM/Random Forest models on the device.
- **Mobile-Server Synchronization**: The mobile app needs to sync its offline queue with the backend once a connection is restored.
- **Containerization**: A `docker-compose.yml` for running the full stack locally.

## What Will Be Reused
- The existing Flutter architecture (`GeoFenceService`, `RiskEngine`, SQLite DB, `AlertService`).
- The offline-first design paradigm ensuring the phone continues to protect users without network connectivity.
- Deterministic geofence rules which take precedence over probabilistic AI predictions.

## What Will Be Added
- **Phase 2 (Backend API)**: Complete FastAPI backend, incidents, and geofencing endpoints.
- **Phase 3 (Database Models)**: Alembic migrations, PostgreSQL, and PostGIS for spatial queries.
- **Phase 4 (Frontend UI)**: Next.js responsive dashboard with live MapLibre/Leaflet maps.
- **Phase 5 (WebSockets)**: Real-time event bus backed by Redis.
- **Phase 6 (Alerts & Notifications)**: Enhanced alert engine and server-side notifications.
- **Phase 7 (Analytics Dashboard)**: Real data analytics and charts.
- **Phase 8 (Security)**: JWT authentication, RBAC, and audit logs.
- **Phase 9 (Documentation)**: API docs and deployment guides.
- **Phase 10 (Docker Support)**: `docker-compose.yml` and containerization for all services.
