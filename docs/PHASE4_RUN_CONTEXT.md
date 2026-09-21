# BSAS Phase 4 Run Context & Environment Specification

## 1. Repository Identification
- **Project Name**: Border Safety & Alert System (BSAS)
- **Repository Root**: `c:\Users\jaget\Desktop\Border Safety Alert System`
- **Directory Structure**:
  ```text
  Border Safety Alert System/
  ├── backend/        # FastAPI + SQLAlchemy Python backend
  ├── frontend/       # Next.js 16 + TailwindCSS v4 web dashboard
  ├── lib/            # Flutter mobile application
  ├── ml/             # Machine Learning scripts, notebooks, datasets
  ├── assets/         # Deployed TFLite & JSON ML model artifacts
  ├── test/           # Flutter unit & widget tests
  ├── tests/          # Project root tests
  └── docs/           # Documentation and verification reports
  ```

---

## 2. Toolchain Versions & Environment
- **OS**: Windows 11 Pro (x64)
- **Python Executable**: `c:\Users\jaget\Desktop\Border Safety Alert System\venv\Scripts\python.exe`
- **Python Version**: Python 3.14.0a4 / 3.11+
- **Node.js Version**: v20+
- **npm Version**: 10+
- **Flutter Version**: Flutter SDK v3.29.0 (Channel stable)
- **Dart Version**: Dart v3.7.0
- **Git Version**: 2.45+

---

## 3. Runtime Topology & Services
- **Database**: SQLite `backend/bsas.db` (SQLAlchemy ORM)
- **Backend API Server**: FastAPI running at `http://localhost:8000/api/v1`
- **Frontend App**: Next.js 16 running at `http://localhost:3000`
- **Authentication**: OAuth2 password flow with JWT Bearer tokens
- **Map Provider**: Leaflet (OpenStreetMap tile server `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`)
- **Realtime Mode**: HTTP Polling (`GET /api/v1/events/poll?since=<timestamp>`) every 10 seconds. No WebSockets or Redis Pub/Sub.

---

## 4. Environment Variables Specification
- `NEXT_PUBLIC_API_URL`: Default `http://localhost:8000/api/v1` (Public)
- `SECRET_KEY`: Backend JWT signing key (Server-only)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: 30 minutes (Server-only)
