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
