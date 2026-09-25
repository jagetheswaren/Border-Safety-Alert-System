import uuid
from sqlalchemy import Column, String, DateTime, Float, ForeignKey, Boolean
from sqlalchemy.sql import func
from app.database import Base
from app.database.spatial import get_geom_column

def generate_uuid():
    return str(uuid.uuid4())

class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String, primary_key=True, default=generate_uuid)
    type = Column(String, nullable=False) # e.g. GEOFENCE_BREACH, VELOCITY_WARNING, RISK_ESCALATION
    severity = Column(String, nullable=False) # CRITICAL, WARNING, CAUTION, SAFE
    title = Column(String, nullable=False)
    message = Column(String, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    device_id = Column(String, nullable=True)
    zone_id = Column(String, ForeignKey("zones.id"), nullable=True)
    incident_id = Column(String, ForeignKey("incidents.id"), nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    geom = get_geom_column("POINT", srid=4326) # Authentic PostGIS Point column
    acknowledged = Column(Boolean, default=False)
    synced = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
