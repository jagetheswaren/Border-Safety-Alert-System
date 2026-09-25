from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List, Optional

from app.dependencies import get_db
from app.models.incident import Incident
from app.models.alert import Alert
from app.schemas.incident import IncidentInDB
from app.schemas.alert import AlertInDB

from app.api.auth import require_operator

router = APIRouter(dependencies=[Depends(require_operator)])

@router.get("/poll")
def poll_events(since: Optional[str] = None, db: Session = Depends(get_db)):
    # Simple polling feed returning recent incidents and alerts
    # `since` is a timestamp string
    
    incidents_query = db.query(Incident)
    alerts_query = db.query(Alert)
    
    if since:
        try:
            since_dt = datetime.fromisoformat(since)
            incidents_query = incidents_query.filter(Incident.created_at >= since_dt)
            alerts_query = alerts_query.filter(Alert.created_at >= since_dt)
        except ValueError:
            pass # Ignore invalid timestamps for now
            
    recent_incidents = incidents_query.order_by(Incident.created_at.desc()).limit(20).all()
    recent_alerts = alerts_query.order_by(Alert.created_at.desc()).limit(20).all()
    
    # Format them generically as events
    events = []
    
    for inc in recent_incidents:
        events.append({
            "id": inc.id,
            "type": "INCIDENT",
            "title": inc.title,
            "severity": inc.severity,
            "timestamp": inc.created_at.isoformat(),
            "data": inc.id
        })
        
    for alt in recent_alerts:
        events.append({
            "id": alt.id,
            "type": "ALERT",
            "title": alt.title,
            "severity": alt.severity,
            "timestamp": alt.created_at.isoformat() if alt.created_at else None,
            "data": alt.id
        })
        
    # Sort events by timestamp descending
    events.sort(key=lambda x: x["timestamp"] if x["timestamp"] else "", reverse=True)
    
    return events[:50]
