import uuid
from sqlalchemy import Column, String, DateTime, Float, ForeignKey, Text
from sqlalchemy.sql import func
from app.database import Base
from app.database.spatial import get_geom_column

def generate_uuid():
    return str(uuid.uuid4())

class Incident(Base):
    __tablename__ = "incidents"

    id = Column(String, primary_key=True, default=generate_uuid)
    incident_number = Column(String, unique=True, index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=False) # SECURITY_BREACH, SUSPICIOUS_APPROACH, GEOFENCE_VIOLATION
    severity = Column(String, nullable=False) # CRITICAL, HIGH, MEDIUM, LOW
    status = Column(String, default="OPEN") # OPEN, INVESTIGATING, IN_PROGRESS, RESOLVED, CLOSED
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    geom = get_geom_column("POINT", srid=4326) # Authentic PostGIS Point column
    zone_id = Column(String, ForeignKey("zones.id"), nullable=True)
    reported_by = Column(String, nullable=True)
    assigned_to = Column(String, nullable=True)
    ai_summary = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    resolved_at = Column(DateTime(timezone=True), nullable=True)
