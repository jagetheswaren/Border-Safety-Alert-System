from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from app.dependencies import get_db
from app.models.incident import Incident
from app.schemas.incident import IncidentInDB, IncidentCreate, IncidentUpdate
from app.schemas.pagination import PaginatedResponse
from datetime import datetime, timezone

from app.api.auth import require_operator

router = APIRouter(dependencies=[Depends(require_operator)])

@router.get("/", response_model=PaginatedResponse[IncidentInDB])
def read_incidents(
    skip: int = 0, 
    limit: int = 100, 
    search: Optional[str] = None,
    severity: Optional[str] = None,
    status: Optional[str] = None,
    category: Optional[str] = None,
    zone_id: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Incident)
    
    if search:
        query = query.filter(or_(
            Incident.title.ilike(f"%{search}%"),
            Incident.description.ilike(f"%{search}%"),
            Incident.incident_number.ilike(f"%{search}%")
        ))
    if severity:
        query = query.filter(Incident.severity == severity)
    if status:
        query = query.filter(Incident.status == status)
    if category:
        query = query.filter(Incident.category == category)
    if zone_id:
        query = query.filter(Incident.zone_id == zone_id)
        
    total = query.count()
    incidents = query.order_by(Incident.created_at.desc()).offset(skip).limit(limit).all()
    
    return PaginatedResponse(
        items=incidents,
        total=total,
        page=(skip // limit) + 1 if limit > 0 else 1,
        size=limit
    )

@router.get("/{incident_id}", response_model=IncidentInDB)
def get_incident(incident_id: str, db: Session = Depends(get_db)):
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return incident

@router.post("/", response_model=IncidentInDB)
def create_incident(incident: IncidentCreate, db: Session = Depends(get_db)):
    data = incident.model_dump()
    if not data.get("incident_number"):
        import uuid
        data["incident_number"] = f"INC-{datetime.now(timezone.utc).year}-{uuid.uuid4().hex[:6].upper()}"
    db_incident = Incident(**data)
    db.add(db_incident)
    db.commit()
    db.refresh(db_incident)
    return db_incident

@router.patch("/{incident_id}", response_model=IncidentInDB)
def update_incident(incident_id: str, update: IncidentUpdate, db: Session = Depends(get_db)):
    db_incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if not db_incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    
    update_data = update.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(db_incident, field, val)
    
    if update.status == "RESOLVED" and not db_incident.resolved_at:
        db_incident.resolved_at = datetime.now(timezone.utc)
    db_incident.updated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(db_incident)
    return db_incident
