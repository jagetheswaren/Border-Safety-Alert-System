import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Float, Text
from sqlalchemy.sql import func
from app.database import Base
from app.database.spatial import get_geom_column

def generate_uuid():
    return str(uuid.uuid4())

class Zone(Base):
    __tablename__ = "zones"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, index=True, nullable=False)
    type = Column(String, nullable=False) # e.g., RESTRICTED, WARNING, BUFFER, SAFE_CORRIDOR
    severity = Column(String, nullable=False) # e.g., CRITICAL, HIGH, MEDIUM, LOW
    geometry = Column(Text, nullable=False) # GeoJSON string
    geom = get_geom_column("POLYGON", srid=4326) # Authentic PostGIS geometry column
    warning_radius_m = Column(Float, default=0.0)
    enabled = Column(Boolean, default=True)
    version = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
