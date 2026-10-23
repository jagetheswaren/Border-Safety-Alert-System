import json
import logging
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any

from app.api.auth import get_current_user
from app.models.user import User

logger = logging.getLogger("bsas.borders")

router = APIRouter()

# Locate border datasets
CURRENT_DIR = Path(__file__).resolve().parent
REPO_ROOT = CURRENT_DIR.parent.parent.parent
BACKEND_DIR = CURRENT_DIR.parent.parent

DATA_DIR = REPO_ROOT / "data" / "borders"
if not DATA_DIR.exists():
    DATA_DIR = BACKEND_DIR / "data" / "borders"

BORDERS_GEOJSON_PATH = DATA_DIR / "borders.geojson"
METADATA_PATH = DATA_DIR / "metadata.json"
ZONES_GEOJSON_PATH = DATA_DIR / "zones.geojson"

def _load_borders_data() -> Dict[str, Any]:
    if not BORDERS_GEOJSON_PATH.exists():
        logger.error(f"Border dataset missing at {BORDERS_GEOJSON_PATH}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Monitored border boundary dataset not found on server."
        )
    try:
        with open(BORDERS_GEOJSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Failed to parse border GeoJSON: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to load boundary GeoJSON dataset."
        )

def _load_metadata() -> Dict[str, Any]:
    if not METADATA_PATH.exists():
        return {
            "dataset": "BSAS Monitored Borders",
            "safety_zones_config": {
                "awarenessMeters": 2000,
                "warningMeters": 1000,
                "criticalMeters": 300
            }
        }
    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

@router.get("/")
def get_all_borders(user: User = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Returns authoritative GeoJSON FeatureCollection of all monitored border demarcation lines.
    Requires authenticated user (field user, operator, or admin).
    """
    return _load_borders_data()

@router.get("/metadata")
def get_borders_metadata(user: User = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Returns official border dataset metadata, authority, licensing, and safety zone distance rules.
    """
    return _load_metadata()

@router.get("/{border_id}")
def get_border_by_id(border_id: str, user: User = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Returns specific border feature by unique identifier.
    """
    data = _load_borders_data()
    for feat in data.get("features", []):
        props = feat.get("properties", {})
        if feat.get("id") == border_id or props.get("id") == border_id:
            return feat
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Border '{border_id}' not found.")
