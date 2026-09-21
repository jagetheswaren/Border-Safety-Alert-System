from sqlalchemy import Column, String, Boolean, DateTime, Float, Text
from sqlalchemy.sql import func
import uuid
from app.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class Zone(Base):
    __tablename__ = "zones"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, index=True, nullable=False)
    type = Column(String, nullable=False) # e.g., RESTRICTED, WARNING
    severity = Column(String, nullable=False) # e.g., CRITICAL, HIGH, MEDIUM
    geometry = Column(Text, nullable=False) # Storing GeoJSON as Text for fallback compatibility
    warning_radius_m = Column(Float, default=0.0)
    enabled = Column(Boolean, default=True)
    version = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
