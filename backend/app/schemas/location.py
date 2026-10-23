from pydantic import BaseModel, Field, AwareDatetime, ConfigDict
from typing import Optional, List
from datetime import datetime

class LocationCreate(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    device_id: str = Field(..., min_length=1, max_length=128, description="Unique hardware or installation identifier of the device")
    latitude: float = Field(..., ge=-90.0, le=90.0, allow_inf_nan=False, description="Latitude in decimal degrees (-90 to +90)")
    longitude: float = Field(..., ge=-180.0, le=180.0, allow_inf_nan=False, description="Longitude in decimal degrees (-180 to +180)")
    accuracy_m: Optional[float] = Field(None, ge=0.0, le=10000.0, description="Horizontal accuracy radius in meters")
    speed_mps: Optional[float] = Field(None, ge=0.0, le=500.0, description="Ground speed in meters per second")
    heading_deg: Optional[float] = Field(None, ge=0.0, le=360.0, description="Direction of travel in degrees (0 to 360)")
    altitude_m: Optional[float] = Field(None, ge=-500.0, le=10000.0, description="Altitude above mean sea level in meters")
    recorded_at: AwareDatetime = Field(..., description="ISO-8601 timestamp with timezone when GPS fix was acquired")

class LocationBatchCreate(BaseModel):
    locations: List[LocationCreate] = Field(..., min_length=1, max_length=500, description="Array of verified location points")

class LocationInDB(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    device_id: Optional[str]
    user_id: Optional[str]
    latitude: float
    longitude: float
    accuracy: Optional[float] = None
    speed: Optional[float] = None
    bearing: Optional[float] = None
    altitude: Optional[float] = None
    timestamp: datetime
    created_at: Optional[datetime] = None
