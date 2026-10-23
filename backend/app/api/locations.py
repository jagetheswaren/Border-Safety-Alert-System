import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from geoalchemy2.elements import WKTElement

from app.dependencies import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.models.device import Device
from app.models.location import LocationBreadcrumb
from app.schemas.location import LocationCreate, LocationBatchCreate, LocationInDB
from app.database import is_postgres

router = APIRouter()

def _ensure_device(db: Session, device_id: str, user_id: str) -> Device:
    device = db.query(Device).filter(Device.device_identifier == device_id).first()
    if device and device.user_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Device identifier belongs to another account.")
    if not device:
        device = Device(device_identifier=device_id, user_id=user_id, is_active=True, last_seen=datetime.now(timezone.utc))
        db.add(device)
        db.flush()
    else:
        if not device.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Device is disabled.")
        device.last_seen = datetime.now(timezone.utc)
    return device

@router.post("/", response_model=LocationInDB, status_code=status.HTTP_201_CREATED)
def record_location(loc: LocationCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """
    Submits a validated real-time GNSS location sample from a field device.
    Strict bounds check on coordinates, timestamps, and authentic user session.
    """
    device = _ensure_device(db, loc.device_id, user.id)
    geom = WKTElement(f"POINT({loc.longitude} {loc.latitude})", srid=4326) if is_postgres else None
    
    breadcrumb = LocationBreadcrumb(
        id=str(uuid.uuid4()),
        device_id=device.id,
        user_id=user.id,
        timestamp=loc.recorded_at,
        latitude=loc.latitude,
        longitude=loc.longitude,
        geom=geom,
        accuracy=loc.accuracy_m,
        speed=loc.speed_mps,
        bearing=loc.heading_deg,
        altitude=loc.altitude_m,
        created_at=datetime.now(timezone.utc)
    )
    db.add(breadcrumb)
    db.commit()
    db.refresh(breadcrumb)
    return breadcrumb

@router.post("/batch", status_code=status.HTTP_201_CREATED)
def record_locations_batch(batch: LocationBatchCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """
    Ingests a series of location breadcrumbs from an offline sync queue or high-rate tracking session.
    """
    inserted_ids = []
    for loc in batch.locations:
        device = _ensure_device(db, loc.device_id, user.id)
        geom = WKTElement(f"POINT({loc.longitude} {loc.latitude})", srid=4326) if is_postgres else None
        breadcrumb = LocationBreadcrumb(
            id=str(uuid.uuid4()),
            device_id=device.id,
            user_id=user.id,
            timestamp=loc.recorded_at,
            latitude=loc.latitude,
            longitude=loc.longitude,
            geom=geom,
            accuracy=loc.accuracy_m,
            speed=loc.speed_mps,
            bearing=loc.heading_deg,
            altitude=loc.altitude_m,
            created_at=datetime.now(timezone.utc)
        )
        db.add(breadcrumb)
        inserted_ids.append(breadcrumb.id)
    
    db.commit()
    return {"status": "SUCCESS", "count": len(inserted_ids), "ids": inserted_ids}

@router.get("/latest", response_model=List[LocationInDB])
def get_latest_locations(limit: int = 50, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """
    Returns latest location fixes across all active devices for live dashboard map display.
    """
    breadcrumbs = db.query(LocationBreadcrumb).order_by(desc(LocationBreadcrumb.timestamp)).limit(limit).all()
    return breadcrumbs
