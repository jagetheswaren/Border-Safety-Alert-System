import sys
import os
import uuid
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app



def test_read_health(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["phase"] == 2

def test_create_and_authenticate_user(client):
    unique_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    raw_password = "SecurePassword123!"

    # 1. Create user
    create_res = client.post(
        "/api/v1/users/",
        json={"email": unique_email, "password": raw_password, "role": "FIELD_USER"}
    )
    assert create_res.status_code == 200
    user_data = create_res.json()
    assert user_data["email"] == unique_email
    assert "id" in user_data

    # 2. Login with correct password
    login_res = client.post(
        "/api/v1/auth/login",
        data={"username": unique_email, "password": raw_password}
    )
    assert login_res.status_code == 200
    token_data = login_res.json()
    assert "access_token" in token_data
    assert token_data["token_type"] == "bearer"
    token = token_data["access_token"]

    # 3. Read /me with token
    me_res = client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert me_res.status_code == 200
    assert me_res.json()["email"] == unique_email

    # 4. Login with wrong password fails
    wrong_login = client.post(
        "/api/v1/auth/login",
        data={"username": unique_email, "password": "WrongPassword!"}
    )
    assert wrong_login.status_code == 400

def test_duplicate_user_rejected(client):
    unique_email = f"dup_{uuid.uuid4().hex[:8]}@example.com"
    client.post(
        "/api/v1/users/",
        json={"email": unique_email, "password": "password123"}
    )
    res = client.post(
        "/api/v1/users/",
        json={"email": unique_email, "password": "password123"}
    )
    assert res.status_code == 400

def test_geofence_check(client):
    response = client.post(
        "/api/v1/geofence/check",
        json={"latitude": 34.0, "longitude": -118.0, "device_id": "dev-123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["risk"] == "UNKNOWN"

def test_dashboard_stats(client):
    response = client.get("/api/v1/dashboard/stats")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)

def test_borders_endpoints(client):
    # 1. Get all borders
    res = client.get("/api/v1/borders/")
    assert res.status_code == 200
    fc = res.json()
    assert fc["type"] == "FeatureCollection"
    assert len(fc["features"]) >= 6

    # 2. Get border metadata
    meta_res = client.get("/api/v1/borders/metadata")
    assert meta_res.status_code == 200
    meta = meta_res.json()
    assert "safety_zones_config" in meta
    assert meta["safety_zones_config"]["criticalMeters"] == 300

    # 3. Get specific border by id
    border_id = fc["features"][0]["properties"]["id"]
    single_res = client.get(f"/api/v1/borders/{border_id}")
    assert single_res.status_code == 200
    assert single_res.json()["properties"]["id"] == border_id

    # 4. Unknown border returns 404
    missing_res = client.get("/api/v1/borders/nonexistent_boundary_id")
    assert missing_res.status_code == 404

def test_location_recording_and_validation(client):
    timestamp_str = "2026-10-03T10:00:00Z"
    
    # 1. Valid location submission
    res = client.post(
        "/api/v1/locations/",
        json={
            "device_id": "test-device-01",
            "latitude": 10.15,
            "longitude": 78.15,
            "accuracy_m": 4.5,
            "speed_mps": 1.2,
            "heading_deg": 180.0,
            "recorded_at": timestamp_str
        }
    )
    assert res.status_code == 201
    loc_data = res.json()
    assert loc_data["latitude"] == 10.15
    assert loc_data["longitude"] == 78.15
    assert loc_data["accuracy"] == 4.5

    # 2. Invalid latitude (out of bounds > 90) fails validation
    invalid_res = client.post(
        "/api/v1/locations/",
        json={
            "device_id": "test-device-01",
            "latitude": 999.0,
            "longitude": 78.15,
            "recorded_at": timestamp_str
        }
    )
    assert invalid_res.status_code == 422

    # 3. Batch location submission
    batch_res = client.post(
        "/api/v1/locations/batch",
        json={
            "locations": [
                {
                    "device_id": "test-device-01",
                    "latitude": 10.16,
                    "longitude": 78.16,
                    "accuracy_m": 5.0,
                    "speed_mps": 2.0,
                    "heading_deg": 185.0,
                    "recorded_at": "2026-10-03T10:01:00Z"
                },
                {
                    "device_id": "test-device-01",
                    "latitude": 10.17,
                    "longitude": 78.17,
                    "accuracy_m": 4.8,
                    "speed_mps": 2.5,
                    "heading_deg": 190.0,
                    "recorded_at": "2026-10-03T10:02:00Z"
                }
            ]
        }
    )
    assert batch_res.status_code == 201
    assert batch_res.json()["count"] == 2

    # 4. Get latest locations
    latest_res = client.get("/api/v1/locations/latest")
    assert latest_res.status_code == 200
    assert len(latest_res.json()) >= 3

def test_incident_crud_and_patch(client):
    # 1. Create incident
    create_res = client.post(
        "/api/v1/incidents/",
        json={
            "title": "Perimeter Gate Alert",
            "description": "Gate sensor tripped near marker 12",
            "category": "SECURITY_BREACH",
            "severity": "HIGH",
            "status": "OPEN",
            "latitude": 10.22,
            "longitude": 78.22
        }
    )
    assert create_res.status_code == 200
    incident_id = create_res.json()["id"]

    # 2. Get incident by id
    get_res = client.get(f"/api/v1/incidents/{incident_id}")
    assert get_res.status_code == 200
    assert get_res.json()["status"] == "OPEN"

    # 3. Patch incident to RESOLVED
    patch_res = client.patch(
        f"/api/v1/incidents/{incident_id}",
        json={
            "status": "RESOLVED",
            "assigned_to": "Officer Ramesh"
        }
    )
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["status"] == "RESOLVED"
    assert updated["assigned_to"] == "Officer Ramesh"
    assert updated["resolved_at"] is not None

def test_alert_crud_and_patch(client):
    # 1. Create alert
    create_res = client.post(
        "/api/v1/alerts/",
        json={
            "type": "GEOFENCE_BREACH",
            "severity": "CRITICAL",
            "title": "Boundary Proximity Alert",
            "message": "Civilian vessel within 200m of exclusion zone",
            "location_lat": 9.35,
            "location_lng": 79.35
        }
    )
    assert create_res.status_code == 200
    alert_id = create_res.json()["id"]

    # 2. Get alert
    get_res = client.get(f"/api/v1/alerts/{alert_id}")
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Boundary Proximity Alert"

    # 3. Patch alert acknowledged and resolved
    patch_res = client.patch(
        f"/api/v1/alerts/{alert_id}",
        json={
            "acknowledged": True,
            "resolved": True
        }
    )
    assert patch_res.status_code == 200
    patched = patch_res.json()
    assert patched["acknowledged_at"] is not None
    assert patched["resolved_at"] is not None
