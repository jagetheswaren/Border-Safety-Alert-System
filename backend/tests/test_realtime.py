import pytest
from fastapi.testclient import TestClient
from app.api.auth import create_access_token

def test_events_stream_unauthorized(client: TestClient):
    # Without token, should reject with 401
    resp = client.get("/api/v1/events/stream")
    assert resp.status_code == 401

def test_events_stream_authorized(client: TestClient):
    # With valid operator token, stream connects
    token = create_access_token({'sub': 'operator@example.test'})
    with client.stream("GET", f"/api/v1/events/stream?token={token}&limit=1") as response:
        assert response.status_code == 200
        assert "text/event-stream" in response.headers["content-type"]
        line = next(response.iter_lines())
        assert "event: initial" in line

def test_websocket_unauthorized(client: TestClient):
    with pytest.raises(Exception):
        with client.websocket_connect("/api/v1/events/ws?token=invalid_token") as ws:
            pass

def test_websocket_authorized_ping_pong(client: TestClient):
    token = create_access_token({'sub': 'operator@example.test'})
    with client.websocket_connect(f"/api/v1/events/ws?token={token}") as ws:
        init_data = ws.receive_json()
        assert init_data.get("type") == "CONNECTION_ESTABLISHED"
        assert init_data.get("protocol") == "BSAS_REALTIME_V1"
        
        # Test ping/pong heartbeat
        ws.send_text('{"type": "PING"}')
        pong = ws.receive_json()
        assert pong.get("type") == "PONG"
        assert "timestamp" in pong
