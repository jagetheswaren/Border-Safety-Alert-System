import uuid
from sqlalchemy import Column, String, DateTime, Float, ForeignKey
from sqlalchemy.sql import func
from app.database import Base
from app.database.spatial import get_geom_column

def generate_uuid():
    return str(uuid.uuid4())

class LocationBreadcrumb(Base):
    __tablename__ = "location_breadcrumbs"

    id = Column(String, primary_key=True, default=generate_uuid)
    device_id = Column(String, ForeignKey("devices.id"), nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    timestamp = Column(DateTime(timezone=True), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    geom = get_geom_column("POINT", srid=4326) # Authentic PostGIS Point column
    accuracy = Column(Float, nullable=True)
    altitude = Column(Float, nullable=True)
    speed = Column(Float, nullable=True)
    bearing = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
