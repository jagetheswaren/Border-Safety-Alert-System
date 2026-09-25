import logging
from fastapi import FastAPI, Depends, Response
from contextlib import asynccontextmanager
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.api import users, zones, incidents, auth, alerts, dashboard, events, geofence, sync
from app.database import engine, init_db, get_db, is_postgres
from app.config import settings

logger = logging.getLogger("bsas.main")

@asynccontextmanager
async def lifespan(app):
    settings.validate_production_security()
    init_db()
    yield

app = FastAPI(
    lifespan=lifespan,
    title="Border Safety Alert System (BSAS) API",
    description="Authoritative backend service for civilian border safety, geofencing, alerts, PostGIS geospatial intelligence, and mobile telemetry sync.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API v1 routes
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(zones.router, prefix="/api/v1/zones", tags=["zones"])
app.include_router(incidents.router, prefix="/api/v1/incidents", tags=["incidents"])
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["alerts"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["dashboard"])
app.include_router(events.router, prefix="/api/v1/events", tags=["events"])
app.include_router(geofence.router, prefix="/api/v1/geofence", tags=["geofence"])
app.include_router(sync.router, prefix="/api/v1/sync", tags=["sync"])

@app.get("/health")
@app.get("/api/v1/health")
def health(response: Response, db: Session = Depends(get_db)) -> dict:
    """
    Comprehensive health check validating database connectivity,
    geospatial backend status, and environment configuration.
    """
    db_status = "UNKNOWN"
    postgis_status = "NOT_CONFIGURED"

    try:
        db.execute(text("SELECT 1;"))
        db_status = "CONNECTED"

        if is_postgres:
            try:
                res = db.execute(text("SELECT PostGIS_Version();")).scalar()
                postgis_status = f"AVAILABLE ({res})"
            except Exception:
                postgis_status = "UNAVAILABLE"
                db.rollback()
        else:
            postgis_status = "SQLITE_GEOMETRIC_FALLBACK"
    except Exception as e:
        db_status = "DISCONNECTED"

    healthy = db_status == "CONNECTED" and (not is_postgres or postgis_status.startswith("AVAILABLE"))
    response.status_code = 200 if healthy else 503
    return {
        "status": "ok" if healthy else "degraded",
        "service": "BSAS Core API",
        "phase": 2,
        "version": "1.0.0",
        "database": {
            "status": db_status,
            "engine": "PostgreSQL" if is_postgres else "SQLite",
            "geospatial": postgis_status,
        },
        "environment": settings.ENVIRONMENT,
    }
