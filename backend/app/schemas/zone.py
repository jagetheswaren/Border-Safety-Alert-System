from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ZoneBase(BaseModel):
    name: str
    type: str
    severity: str
    geometry: str
    warning_radius_m: Optional[float] = 0.0
    enabled: Optional[bool] = True
    version: Optional[str] = None

class ZoneCreate(ZoneBase):
    pass

class ZoneUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    severity: Optional[str] = None
    geometry: Optional[str] = None
    warning_radius_m: Optional[float] = None
    enabled: Optional[bool] = None
    version: Optional[str] = None

class ZoneInDB(ZoneBase):
    id: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
