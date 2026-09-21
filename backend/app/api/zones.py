from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.dependencies import get_db
from app.models.zone import Zone
from app.schemas.zone import ZoneInDB, ZoneCreate

router = APIRouter()

@router.get("/", response_model=List[ZoneInDB])
def read_zones(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    zones = db.query(Zone).offset(skip).limit(limit).all()
    return zones

@router.post("/", response_model=ZoneInDB)
def create_zone(zone: ZoneCreate, db: Session = Depends(get_db)):
    db_zone = Zone(**zone.model_dump())
    db.add(db_zone)
    db.commit()
    db.refresh(db_zone)
    return db_zone
