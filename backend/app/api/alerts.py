from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from datetime import datetime

from app.dependencies import get_db
from app.models.alert import Alert
from app.schemas.alert import AlertInDB, AlertCreate
from app.schemas.pagination import PaginatedResponse

from app.api.auth import require_operator

router = APIRouter(dependencies=[Depends(require_operator)])

@router.get("/", response_model=PaginatedResponse[AlertInDB])
def read_alerts(
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None,
    type: Optional[str] = None,
    severity: Optional[str] = None,
    zone_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Alert)
    
    if search:
        query = query.filter(or_(
            Alert.title.ilike(f"%{search}%"),
            Alert.message.ilike(f"%{search}%")
        ))
    if type:
        query = query.filter(Alert.type == type)
    if severity:
        query = query.filter(Alert.severity == severity)
    if zone_id:
        query = query.filter(Alert.zone_id == zone_id)
        
    total = query.count()
    alerts = query.order_by(Alert.created_at.desc()).offset(skip).limit(limit).all()
    
    return PaginatedResponse(
        items=alerts,
        total=total,
        page=(skip // limit) + 1 if limit > 0 else 1,
        size=limit
    )

@router.post("/", response_model=AlertInDB)
def create_alert(alert: AlertCreate, db: Session = Depends(get_db)):
    db_alert = Alert(**alert.model_dump())
    db.add(db_alert)
    db.commit()
    db.refresh(db_alert)
    return db_alert

@router.post("/bulk", status_code=201)
def create_alerts_bulk(events: List[dict], db: Session = Depends(get_db)):
    """
    Accepts bulk event payloads from the mobile sync engine, inserting
    unseen alerts and returning acknowledged event IDs.
    """
    synced_ids = []
    for item in events:
        eid = item.get("event_id")
        if not eid:
            continue
        existing = db.query(Alert).filter(Alert.id == eid).first()
        if not existing:
            db_alert = Alert(
                id=eid,
                type=item.get("event_type", "SAFETY_ALERT"),
                severity=item.get("risk_state", "WARNING"),
                title=item.get("alert_state", "Border Alert"),
                message=f"Zone: {item.get('zone', 'Unknown')}. AI: {item.get('ai_state', 'NORMAL')}",
                location_lat=item.get("latitude"),
                location_lng=item.get("longitude"),
            )
            db.add(db_alert)
        synced_ids.append(eid)
    db.commit()
    return {"status": "SUCCESS", "synced_count": len(synced_ids), "acknowledged_ids": synced_ids}

