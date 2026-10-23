from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any

class BorderProperties(BaseModel):
    id: str
    boundary_name: str
    region_a: Optional[str] = None
    region_b: Optional[str] = None
    source: Optional[str] = None
    source_date: Optional[str] = None
    boundary_type: Optional[str] = "restricted"
    risk_level: Optional[str] = "CRITICAL"
    description: Optional[str] = None

class BorderGeometry(BaseModel):
    type: str
    coordinates: Any

class BorderFeature(BaseModel):
    type: str = "Feature"
    id: str
    properties: BorderProperties
    geometry: BorderGeometry

class BorderFeatureCollection(BaseModel):
    type: str = "FeatureCollection"
    metadata: Dict[str, Any]
    features: List[BorderFeature]
