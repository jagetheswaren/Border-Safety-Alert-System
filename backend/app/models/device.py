import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class Device(Base):
    __tablename__ = "devices"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    device_identifier = Column(String, unique=True, index=True, nullable=False)
    device_model = Column(String, nullable=True) # e.g. Samsung Galaxy A12s
    os_version = Column(String, nullable=True) # e.g. Android 11 / API 30
    app_version = Column(String, nullable=True) # e.g. 1.0.0
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
