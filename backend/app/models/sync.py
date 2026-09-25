import uuid
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey, Text
from sqlalchemy.sql import func
from app.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class SyncReceipt(Base):
    __tablename__ = "sync_receipts"

    id = Column(String, primary_key=True, default=generate_uuid)
    device_id = Column(String, nullable=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=True)
    batch_size = Column(Integer, nullable=False, default=0)
    synced_events_count = Column(Integer, nullable=False, default=0)
    status = Column(String, nullable=False, default="SUCCESS") # SUCCESS, PARTIAL, FAILED
    client_timestamp = Column(DateTime(timezone=True), nullable=True)
    server_timestamp = Column(DateTime(timezone=True), server_default=func.now())


class SafetyEvent(Base):
    __tablename__ = 'safety_events'
    event_id = Column(String, primary_key=True)
    device_id = Column(String, ForeignKey('devices.id'), nullable=False, index=True)
    user_id = Column(String, ForeignKey('users.id'), nullable=False, index=True)
    payload_json = Column(Text, nullable=False)
    payload_sha256 = Column(String(64), nullable=False)
    captured_at = Column(DateTime(timezone=True), nullable=False)
    received_at = Column(DateTime(timezone=True), server_default=func.now())
