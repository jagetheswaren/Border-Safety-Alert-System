from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class AlertBase(BaseModel):
    type: str
    severity: str
    title: str
    message: str
    user_id: Optional[str] = None
    device_id: Optional[str] = None
    zone_id: Optional[str] = None
    incident_id: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None

class AlertCreate(AlertBase):
    pass

class AlertInDB(AlertBase):
    id: str
    created_at: datetime
    acknowledged_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

    class Config:
        from_attributes = True
