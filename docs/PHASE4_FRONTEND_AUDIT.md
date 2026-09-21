# PHASE 4 FRONTEND AUDIT

## 1. Existing System Architecture
- **Frontend**: The `frontend/` directory does not currently exist. A new Next.js application will be scaffolded here.
- **Mobile (Flutter)**: Located in the root (`lib/`, `android/`, `ios/`). This is an offline-first app that handles geofencing locally. It must be preserved and untested code must not break it.
- **Backend (FastAPI)**: Located in `backend/`. The database models for Users, Zones, Incidents, and Alerts are defined. It uses SQLite for dev. 

## 2. API Inventory (Current State)
The backend API exposes the following endpoints:
- `GET /api/v1/users`, `POST /api/v1/users`
- `GET /api/v1/zones`, `POST /api/v1/zones`
- `GET /api/v1/incidents`, `POST /api/v1/incidents`
- `POST /api/v1/geofence/check`
- `GET /health`

## 3. Missing API Capabilities (To be Added)
To support the Phase 4 Production Frontend strictly with "REAL DATA ONLY" and no mock data, the following minimal backend extensions are required:
1. **Authentication & RBAC (`/api/v1/auth`)**: We need a `/login` endpoint to issue a JWT token, and a `/me` endpoint to fetch the current user and their role (`SUPER_ADMIN`, `OPERATOR`, etc.).
2. **Alerts API (`/api/v1/alerts`)**: A router for querying and updating Alerts, as they are part of the core dashboard but currently lack a router.
3. **Dashboard Aggregate API (`/api/v1/dashboard/stats`)**: For calculating dashboard metrics (active users, open incidents, critical alerts) directly from the DB.
4. **Event Polling API (`/api/v1/events/poll`)**: For the HTTP-polling based live event feed. It will query recently created/updated Incidents and Alerts.
5. **Search/Filters**: The `GET` endpoints for users, incidents, zones, and alerts need query parameters (e.g., `?severity=CRITICAL&status=OPEN`) for the filtering requirements.

## 4. Frontend Technology Stack (Planned)
- **Framework**: Next.js (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS, generic unstyled components
- **State/Querying**: TanStack Query (React Query) for caching and HTTP polling.
- **Mapping**: Leaflet (via `react-leaflet`) for interactive maps.

## 5. Technical Risks & Constraints
- **Geospatial Processing**: PostGIS is required for full zone tracking, but SQLite fallback might be used if Postgres is unavailable. Map markers will use raw lat/lng from models for now.
- **Event Feed Polling**: Need to implement a cursor-based or timestamp-based query parameter (e.g. `?since=1690000000`) for the polling loop to prevent refetching the entire DB.
- **No WebSockets**: We must strictly adhere to HTTP polling for the event feed. WebSockets are deferred to Phase 5.
- **Mobile App Preservation**: The backend changes must be strictly additive so as to not break the Flutter app's existing model definitions or endpoints.
