import json
import math
from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy import Column, Text
from geoalchemy2 import Geometry
from app.database import is_postgres

def get_geom_column(geom_type: str, srid: int = 4326):
    """
    Returns an authentic PostGIS GeoAlchemy2 Geometry column when running on PostgreSQL,
    or a fallback Text column on SQLite for local non-spatial unit tests.
    """
    if is_postgres:
        return Column(Geometry(geometry_type=geom_type, srid=srid, spatial_index=True), nullable=True)
    return Column(Text, nullable=True)

def point_to_wkt(lat: float, lon: float) -> str:
    """Creates PostGIS-standard WKT POINT string (longitude latitude)."""
    return f"POINT({lon} {lat})"

def polygon_to_wkt(coordinates: List[List[List[float]]]) -> str:
    """
    Converts GeoJSON Polygon coordinates [[[lon, lat], ...]] to PostGIS WKT.
    """
    rings = []
    for ring in coordinates:
        points = [f"{pt[0]} {pt[1]}" for pt in ring]
        rings.append(f"({', '.join(points)})")
    return f"POLYGON({', '.join(rings)})"

def point_in_polygon(lat: float, lon: float, polygon_coords: List[List[float]]) -> bool:
    """
    Authoritative deterministic ray-casting point-in-polygon math (fallback for SQLite).
    """
    inside = False
    j = len(polygon_coords) - 1
    for i in range(len(polygon_coords)):
        xi, yi = polygon_coords[i][0], polygon_coords[i][1]
        xj, yj = polygon_coords[j][0], polygon_coords[j][1]
        intersect = ((yi > lat) != (yj > lat)) and (
            lon < (xj - xi) * (lat - yi) / (yj - yi + 1e-12) + xi
        )
        if intersect:
            inside = not inside
        j = i
    return inside

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates great-circle distance between two points in meters."""
    R = 6371000.0 # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (math.sin(delta_phi / 2.0) ** 2 +
         math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2)
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c
