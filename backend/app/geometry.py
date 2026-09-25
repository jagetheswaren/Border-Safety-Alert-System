"""Validated zone geometry; SQLite distance is for isolated development tests only."""
import json
import math
from shapely import wkt
from shapely.geometry import shape, Point
from shapely.ops import transform


def parse_polygon(value: str):
    polygon = shape(json.loads(value)) if value.lstrip().startswith('{') else wkt.loads(value)
    if polygon.geom_type not in ('Polygon', 'MultiPolygon') or polygon.is_empty or not polygon.is_valid:
        raise ValueError('A valid nonempty Polygon or MultiPolygon is required')
    min_x, min_y, max_x, max_y = polygon.bounds
    if not (-180 <= min_x <= max_x <= 180 and -90 <= min_y <= max_y <= 90):
        raise ValueError('Geometry coordinates must be WGS84 longitude/latitude')
    return polygon


def local_test_distance(polygon, latitude: float, longitude: float):
    point = Point(longitude, latitude)
    inside = polygon.covers(point)
    # Local approximation, never used for production PostGIS queries.
    scale_x = 111195.08 * math.cos(math.radians(latitude))
    project = lambda x, y, z=None: ((x - longitude) * scale_x, (y - latitude) * 111195.08)
    return inside, float(transform(project, polygon).distance(Point(0, 0)))
