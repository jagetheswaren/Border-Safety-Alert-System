import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.json()["phase"] == 2

def test_create_user():
    import uuid
    unique_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    response = client.post(
        "/api/v1/users/",
        json={"email": unique_email, "password": "password123", "role": "FIELD_USER"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == unique_email
    assert "id" in data

def test_geofence_check():
    response = client.post(
        "/api/v1/geofence/check",
        json={"latitude": 34.0, "longitude": -118.0, "device_id": "dev-123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["risk"] == "SAFE"
