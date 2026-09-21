from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import users, zones, incidents, auth, alerts, dashboard, events, geofence
from app.database import engine
from app.models import user, zone, incident, alert
from app.config import settings

# Create tables (In a real app, use Alembic)
user.Base.metadata.create_all(bind=engine)
zone.Base.metadata.create_all(bind=engine)
incident.Base.metadata.create_all(bind=engine)
alert.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Border Safety Alert System (BSAS) API", version="1.0.0")

# Startup security validation
@app.on_event("startup")
def on_startup() -> None:
    settings.validate_production_security()

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(zones.router, prefix="/api/v1/zones", tags=["zones"])
app.include_router(incidents.router, prefix="/api/v1/incidents", tags=["incidents"])
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["alerts"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["dashboard"])
app.include_router(events.router, prefix="/api/v1/events", tags=["events"])
app.include_router(geofence.router, prefix="/api/v1/geofence", tags=["geofence"])

@app.get("/health")
def health() -> dict:
    return {"status": "ok", "phase": 2, "environment": settings.ENVIRONMENT}
