from fastapi import APIRouter, Depends
from pydantic import BaseModel

router = APIRouter()

class GeofenceCheckRequest(BaseModel):
    latitude: float
    longitude: float
    device_id: str

@router.post("/check")
def check_geofence(req: GeofenceCheckRequest):
    # Stub logic for deterministic geofence checking without postgis
    return {
        "risk": "SAFE",
        "inside_restricted_zone": False,
        "nearest_zone_id": None,
        "distance_m": 1000.0,
        "warning_distance_m": 250,
        "predicted_crossing": False,
        "prediction_horizon_minutes": 5
    }
