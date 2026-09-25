import sys
import os
import uuid
import pytest
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app



def test_batch_sync_pipeline(client):
    device_id = f"test-dev-{uuid.uuid4().hex[:6]}"
    sync_payload = {
        "device_id": device_id,
        "client_timestamp": "2026-09-25T14:30:00Z",
        "events": [
            {
                "event_id": f"evt-{uuid.uuid4().hex[:8]}",
                "timestamp": "2026-09-25T14:28:00Z",
                "event_type": "ZONE_ENTRY",
                "latitude": 10.712530,
                "longitude": 76.979150,
                "zone": "BUFFER_ZONE",
                "risk_state": "CAUTION",
                "ai_state": "ACTIVE",
                "alert_state": "CAUTION",
                "device_id": device_id
            },
            {
                "event_id": f"evt-{uuid.uuid4().hex[:8]}",
                "timestamp": "2026-09-25T14:29:00Z",
                "event_type": "WARNING_TRIGGER",
                "latitude": 10.712600,
                "longitude": 76.979200,
                "zone": "DEMARCATION_LINE",
                "risk_state": "WARNING",
                "ai_state": "ACTIVE",
                "alert_state": "WARNING",
                "device_id": device_id
            }
        ]
    }

    # Post batch sync
    res = client.post("/api/v1/sync/batch", json=sync_payload)
    assert res.status_code == 200, res.text
    data = res.json()
    assert data["status"] == "SUCCESS"
    assert data["synced_count"] == 2
    assert len(data["acknowledged_ids"]) == 2

    # Check sync status
    status_res = client.get(f"/api/v1/sync/status/{device_id}")
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert status_data["device_id"] == device_id
    assert status_data["synced_events"] >= 2

def test_alerts_bulk_upload(client):
    device_id = f"dev-bulk-{uuid.uuid4().hex[:6]}"
    bulk_alerts = [
        {
            "event_id": f"evt-{uuid.uuid4().hex[:8]}",
            "device_id": device_id,
            "type": "BUFFER_ENTRY",
            "message": "Vessel entered 500m demarcation buffer",
            "severity": "CAUTION",
            "latitude": 9.2831,
            "longitude": 79.3125,
            "timestamp": "2026-09-25T14:00:00Z"
        },
        {
            "event_id": f"evt-{uuid.uuid4().hex[:8]}",
            "device_id": device_id,
            "type": "CRITICAL_DRIFT",
            "message": "Rapid current drift detected towards boundary",
            "severity": "CRITICAL",
            "latitude": 9.2810,
            "longitude": 79.3190,
            "timestamp": "2026-09-25T14:02:00Z"
        }
    ]

    res = client.post("/api/v1/alerts/bulk", json=bulk_alerts)
    assert res.status_code in [200, 201], res.text
    data = res.json()
    assert data["status"] == "SUCCESS"
    assert data["synced_count"] == 2

def test_zones_and_spatial_query(client):
    # 1. Create a zone
    zone_payload = {
        "name": f"Palk Strait Buffer {uuid.uuid4().hex[:4]}",
        "type": "BUFFER",
        "severity": "WARNING",
        "geometry": "POLYGON((79.25 9.25, 79.25 9.35, 79.40 9.35, 79.40 9.25, 79.25 9.25))",
        "warning_radius_m": 500.0,
        "enabled": True
    }
    create_res = client.post("/api/v1/zones/", json=zone_payload)
    assert create_res.status_code in [200, 201], create_res.text
    zone_data = create_res.json()
    assert "id" in zone_data

    # 2. Query zones within distance
    within_res = client.get("/api/v1/zones/within?latitude=9.30&longitude=79.30&radius_m=50000")
    assert within_res.status_code == 200, within_res.text
    zones = within_res.json()
    assert isinstance(zones, list)
    assert len(zones) >= 1

def test_auth_refresh_token(client):
    unique_email = f"refresh_user_{uuid.uuid4().hex[:6]}@example.com"
    raw_password = "SecurePassword456!"

    # Register
    reg_res = client.post(
        "/api/v1/auth/register",
        json={"email": unique_email, "password": raw_password, "role": "FIELD_USER"}
    )
    assert reg_res.status_code == 201, reg_res.text

    # Login to get token
    login_res = client.post(
        "/api/v1/auth/login",
        data={"username": unique_email, "password": raw_password}
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]

    # Refresh
    refresh_res = client.post(
        "/api/v1/auth/refresh",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert refresh_res.status_code == 200, refresh_res.text
    new_token = refresh_res.json()["access_token"]
    assert new_token != ""
    assert isinstance(new_token, str)
