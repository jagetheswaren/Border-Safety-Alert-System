from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.dependencies import get_db
from app.models.user import User
from app.models.incident import Incident
from app.models.alert import Alert

from app.api.auth import require_operator

router = APIRouter(dependencies=[Depends(require_operator)])

@router.get("/stats")
def get_dashboard_stats(db: Session = Depends(get_db)):
    active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar()
    open_incidents = db.query(func.count(Incident.id)).filter(Incident.status.in_(["OPEN", "INVESTIGATING"])).scalar()
    critical_alerts = db.query(func.count(Alert.id)).filter(Alert.severity == "CRITICAL", Alert.resolved_at == None).scalar()
    
    return {
        "active_users": active_users,
        "open_incidents": open_incidents,
        "critical_alerts": critical_alerts,
        "current_risk": "HIGH" if critical_alerts > 0 else "MODERATE" if open_incidents > 0 else "SAFE"
    }
