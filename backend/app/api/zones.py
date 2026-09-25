import json
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Optional
from app.dependencies import get_db
from app.models.zone import Zone
from app.geometry import parse_polygon
from geoalchemy2.elements import WKTElement
from app.schemas.zone import ZoneInDB, ZoneCreate
from app.database import is_postgres
from app.database.spatial import point_in_polygon, polygon_to_wkt, haversine_distance

from app.api.auth import get_current_user, require_operator

router = APIRouter(dependencies=[Depends(get_current_user)])

@router.get("/", response_model=List[ZoneInDB])
def read_zones(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    zones = db.query(Zone).filter(Zone.enabled == True).offset(skip).limit(limit).all()
    return zones

@router.get("/within", response_model=List[ZoneInDB])
def query_zones_near_point(
    latitude: float = Query(..., description="Latitude in decimal degrees"),
    longitude: float = Query(..., description="Longitude in decimal degrees"),
    radius_m: float = Query(5000.0, description="Search radius in meters"),
    db: Session = Depends(get_db),
):
    """
    Geospatial query returning safety zones containing or within radius of a GNSS fix.
    Executes native PostGIS ST_DWithin / ST_Contains on PostgreSQL,
    with geometric fallback calculation on SQLite.
    """
    if is_postgres:
        # Native PostGIS spatial query using GIST index
        sql = text("""
            SELECT id, name, type, severity, geometry, warning_radius_m, enabled, version, created_at, updated_at
            FROM zones
            WHERE enabled = true
              AND (
                ST_Contains(geom, ST_SetSRID(ST_Point(:lon, :lat), 4326))
                OR
                ST_DWithin(geom::geography, ST_SetSRID(ST_Point(:lon, :lat), 4326)::geography, :radius)
              )
            LIMIT 50;
        """)
        result = db.execute(sql, {"lat": latitude, "lon": longitude, "radius": radius_m}).fetchall()
        matching_zones = []
        for r in result:
            matching_zones.append(Zone(
                id=r.id, name=r.name, type=r.type, severity=r.severity,
                geometry=r.geometry, warning_radius_m=r.warning_radius_m,
                enabled=r.enabled, version=r.version, created_at=r.created_at,
                updated_at=r.updated_at
            ))
        return matching_zones
    else:
        # Mathematical fallback for SQLite or non-PostGIS deployments
        all_zones = db.query(Zone).filter(Zone.enabled == True).all()
        matching = []
        for z in all_zones:
            try:
                coords = []
                geom_str = z.geometry.strip()
                if geom_str.startswith("{"):
                    geo = json.loads(geom_str)
                    if geo.get("type") == "Polygon" and geo.get("coordinates"):
                        coords = geo["coordinates"][0]
                elif geom_str.upper().startswith("POLYGON"):
                    # Parse WKT: POLYGON((x y, x y, ...))
                    inner = geom_str[geom_str.find("((") + 2 : geom_str.find("))")]
                    pairs = inner.split(",")
                    for p in pairs:
                        parts = p.strip().split()
                        if len(parts) >= 2:
                            coords.append([float(parts[0]), float(parts[1])])
                
                if coords:
                    # Check containment
                    if point_in_polygon(latitude, longitude, coords):
                        matching.append(z)
                        continue
                    # Check distance to any vertex
                    min_dist = min(haversine_distance(latitude, longitude, pt[1], pt[0]) for pt in coords)
                    if min_dist <= (radius_m + (z.warning_radius_m or 0.0)):
                        matching.append(z)
            except Exception as ex:
                continue
        return matching

@router.get("/{zone_id}", response_model=ZoneInDB)
def get_zone(zone_id: str, db: Session = Depends(get_db)):
    zone = db.query(Zone).filter(Zone.id == zone_id).first()
    if not zone:
        raise HTTPException(status_code=404, detail="Zone not found")
    return zone

@router.post("/", response_model=ZoneInDB, status_code=status.HTTP_201_CREATED, dependencies=[Depends(require_operator)])
def create_zone(zone: ZoneCreate, db: Session = Depends(get_db)):
    zone_data = zone.model_dump()
    
    try:
        polygon = parse_polygon(zone.geometry)
        if polygon.geom_type != 'Polygon':
            raise ValueError('This endpoint requires a Polygon')
    except Exception:
        raise HTTPException(422, 'Invalid WGS84 Polygon geometry')
    if is_postgres:
        zone_data['geom'] = WKTElement(polygon.wkt, srid=4326)

    db_zone = Zone(**zone_data)
    db.add(db_zone)
    db.commit()
    db.refresh(db_zone)
    return db_zone
