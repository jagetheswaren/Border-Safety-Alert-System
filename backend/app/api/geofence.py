from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.dependencies import get_db
from app.api.auth import get_current_user
from app.database import is_postgres
from app.models.zone import Zone
from app.geometry import parse_polygon, local_test_distance

router = APIRouter(dependencies=[Depends(get_current_user)])


class GeofenceCheckRequest(BaseModel):
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)
    device_id: str | None = None


@router.post('/check')
def check_geofence(req: GeofenceCheckRequest, db: Session = Depends(get_db)):
    if is_postgres:
        rows = db.execute(text('''
            SELECT id, warning_radius_m,
              ST_Covers(geom, ST_SetSRID(ST_Point(:lon, :lat),4326)) AS inside,
              ST_Distance(geom::geography,
                ST_SetSRID(ST_Point(:lon, :lat),4326)::geography) AS distance
            FROM zones WHERE enabled AND geom IS NOT NULL
            ORDER BY distance LIMIT 1
        '''), {'lat': req.latitude, 'lon': req.longitude}).mappings().all()
    else:
        rows = []
        for zone in db.query(Zone).filter(Zone.enabled.is_(True)).all():
            try:
                inside, distance = local_test_distance(parse_polygon(zone.geometry), req.latitude, req.longitude)
            except (ValueError, TypeError):
                raise HTTPException(503, 'Boundary geometry is invalid; evaluation unavailable')
            rows.append(dict(id=zone.id, warning_radius_m=zone.warning_radius_m,
                             inside=inside, distance=distance))
        rows.sort(key=lambda row: row['distance'])
    if not rows:
        return dict(risk='UNKNOWN', inside_restricted_zone=None, nearest_zone_id=None,
                    distance_m=None, warning_distance_m=None, predicted_crossing=None,
                    reason='No configured safety boundary data available')
    nearest = rows[0]
    warning = nearest['warning_radius_m'] or 0.0
    risk = 'CRITICAL' if nearest['inside'] else 'WARNING' if nearest['distance'] <= warning else 'SAFE'
    return dict(risk=risk, inside_restricted_zone=bool(nearest['inside']),
                nearest_zone_id=nearest['id'], distance_m=nearest['distance'],
                warning_distance_m=warning, predicted_crossing=None)
