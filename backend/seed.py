import json
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from app.database import engine, SessionLocal
from app.models import user, zone, incident, alert
from app.models.user import User
from app.models.zone import Zone
from app.models.incident import Incident
from app.models.alert import Alert

def seed_db():
    db = SessionLocal()
    
    # 1. Admin user
    admin = db.query(User).filter(User.email == "admin@bsas.local").first()
    if not admin:
        print("Creating admin user...")
        admin = User(
            id="usr_admin_001",
            email="admin@bsas.local",
            hashed_password="hashed_placeholder",
            role="DISPATCHER",
            is_active=True
        )
        db.add(admin)

    # 2. Zones
    existing_zones = db.query(Zone).first()
    if not existing_zones:
        print("Seeding demo zones...")
        zone1 = Zone(
            id="zn_001",
            name="Sector 7 Restricted Border Zone",
            type="RESTRICTED",
            severity="CRITICAL",
            geometry=json.dumps({
                "type": "Polygon",
                "coordinates": [[[78.10, 10.10], [78.20, 10.10], [78.20, 10.20], [78.10, 10.20], [78.10, 10.10]]]
            }),
            warning_radius_m=500.0,
            enabled=True,
            version="1.0.0"
        )
        zone2 = Zone(
            id="zn_002",
            name="Sector 4 Warning Buffer Zone",
            type="WARNING",
            severity="HIGH",
            geometry=json.dumps({
                "type": "Polygon",
                "coordinates": [[[78.50, 10.50], [78.60, 10.50], [78.60, 10.60], [78.50, 10.60], [78.50, 10.50]]]
            }),
            warning_radius_m=250.0,
            enabled=True,
            version="1.0.0"
        )
        zone3 = Zone(
            id="zn_003",
            name="Sector 2 Patrol Monitoring Zone",
            type="MONITORING",
            severity="MEDIUM",
            geometry=json.dumps({
                "type": "Polygon",
                "coordinates": [[[78.30, 10.30], [78.40, 10.30], [78.40, 10.40], [78.30, 10.40], [78.30, 10.30]]]
            }),
            warning_radius_m=100.0,
            enabled=True,
            version="1.0.0"
        )
        db.add_all([zone1, zone2, zone3])

    # 3. Incidents
    existing_incidents = db.query(Incident).first()
    if not existing_incidents:
        print("Seeding demo incidents...")
        inc1 = Incident(
            id="inc_001",
            incident_number="INC-2026-001",
            title="Perimeter Fence Motion Anomaly",
            description="Thermal imaging sensor detected unauthorized motion near marker 42 in Sector 7.",
            category="SECURITY_BREACH",
            severity="CRITICAL",
            status="OPEN",
            latitude=10.15,
            longitude=78.15,
            zone_id="zn_001",
            reported_by="sensor_thermal_07",
            assigned_to="unit_alpha_01",
            ai_summary="High confidence spatial anomaly detected by edge RF model. Risk Class: HIGH.",
            created_at=datetime.now(timezone.utc)
        )
        inc2 = Incident(
            id="inc_002",
            incident_number="INC-2026-002",
            title="Unidentified Vehicle Approach",
            description="Vehicle moving at high speed towards Sector 4 warning buffer zone.",
            category="SUSPICIOUS_VEHICLE",
            severity="HIGH",
            status="IN_PROGRESS",
            latitude=10.55,
            longitude=78.55,
            zone_id="zn_002",
            reported_by="radar_tower_04",
            assigned_to="unit_bravo_02",
            ai_summary="LSTM trajectory model predicts buffer threshold breach within 90 seconds.",
            created_at=datetime.now(timezone.utc)
        )
        inc3 = Incident(
            id="inc_003",
            incident_number="INC-2026-003",
            title="Patrol Communications Timeout",
            description="Field Unit Charlie failed scheduled check-in signal in Sector 2.",
            category="COMMUNICATION_LOSS",
            severity="MEDIUM",
            status="RESOLVED",
            latitude=10.35,
            longitude=78.35,
            zone_id="zn_003",
            reported_by="system_watchdog",
            assigned_to="dispatcher_head",
            ai_summary="Transient signal drop confirmed due to terrain shadow. Unit acknowledged safety.",
            created_at=datetime.now(timezone.utc)
        )
        db.add_all([inc1, inc2, inc3])
        
    # 4. Alerts
    existing_alerts = db.query(Alert).first()
    if not existing_alerts:
        print("Seeding demo alerts...")
        alt1 = Alert(
            id="alt_001",
            type="GEOFENCE_BREACH",
            severity="CRITICAL",
            title="Unauthorized Entry Breach",
            message="Motion sensor tripped inside Sector 7 restricted zone.",
            zone_id="zn_001",
            incident_id="inc_001",
            location_lat=10.15,
            location_lng=78.15,
            created_at=datetime.now(timezone.utc)
        )
        alt2 = Alert(
            id="alt_002",
            type="SPEED_WARNING",
            severity="HIGH",
            title="High Speed Approach Alert",
            message="Vehicle exceeding 80 km/h in Sector 4 approach route.",
            zone_id="zn_002",
            incident_id="inc_002",
            location_lat=10.55,
            location_lng=78.55,
            created_at=datetime.now(timezone.utc)
        )
        db.add_all([alt1, alt2])

    db.commit()
    db.close()
    print("Database seeding completed successfully.")

if __name__ == "__main__":
    user.Base.metadata.create_all(bind=engine)
    zone.Base.metadata.create_all(bind=engine)
    incident.Base.metadata.create_all(bind=engine)
    alert.Base.metadata.create_all(bind=engine)
    seed_db()
