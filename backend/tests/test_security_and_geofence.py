from datetime import timedelta
from app.api.auth import create_access_token
from app.database import SessionLocal
from app.models.alert import Alert
from app.models.device import Device
from app.models.location import LocationBreadcrumb
from app.models.sync import SafetyEvent, SyncReceipt


def test_protected_routes_reject_missing_and_invalid_tokens(anonymous):
    for route in ['users/', 'zones/', 'alerts/', 'incidents/', 'dashboard/stats', 'events/poll', 'sync/status/unknown']:
        assert anonymous.get('/api/v1/' + route).status_code == 401
        assert anonymous.get('/api/v1/' + route, headers={'Authorization': 'Bearer invalid'}).status_code == 401


def test_registration_cannot_assign_admin_and_expired_token_is_rejected(anonymous):
    r = anonymous.post('/api/v1/auth/register', json={'email': 'field@example.test', 'password': 'Password123!', 'role': 'ADMIN'})
    assert r.status_code == 201
    assert r.json()['role'] == 'FIELD_USER'
    token = anonymous.post('/api/v1/auth/login', data={'username': 'field@example.test', 'password': 'Password123!'}).json()['access_token']
    headers = {'Authorization': 'Bearer ' + token}
    assert anonymous.get('/api/v1/users/', headers=headers).status_code == 403
    assert anonymous.post('/api/v1/zones/', headers=headers, json={}).status_code == 403
    expired = create_access_token({'sub': 'field@example.test'}, timedelta(seconds=-10))
    assert anonymous.get('/api/v1/auth/me', headers={'Authorization': 'Bearer ' + expired}).status_code == 401
    assert anonymous.post('/api/v1/auth/login', data={'username': 'field@example.test', 'password': 'incorrect'}).status_code == 400


def test_geofence_uses_geometry_and_reports_missing_data(client):
    endpoint = '/api/v1/geofence/check'
    assert client.post(endpoint, json={'latitude': 10, 'longitude': 77}).json()['risk'] == 'UNKNOWN'
    zone = client.post('/api/v1/zones/', json={'name': 'Isolated test polygon', 'type': 'RESTRICTED', 'severity': 'CRITICAL', 'geometry': 'POLYGON((77 10,77.01 10,77.01 10.01,77 10.01,77 10))', 'warning_radius_m': 250, 'enabled': True})
    assert zone.status_code == 201, zone.text
    inside = client.post(endpoint, json={'latitude': 10.005, 'longitude': 77.005}).json()
    assert inside['risk'] == 'CRITICAL' and inside['inside_restricted_zone']
    near = client.post(endpoint, json={'latitude': 10.005, 'longitude': 76.999}).json()
    assert near['risk'] == 'WARNING' and 90 < near['distance_m'] < 120
    assert client.post(endpoint, json={'latitude': 11, 'longitude': 78}).json()['risk'] == 'SAFE'
    assert client.post(endpoint, json={'latitude': 100, 'longitude': 77}).status_code == 422


def test_sync_replay_is_idempotent_and_conflicting_payload_rejected(client):
    event = dict(event_id='event-1', timestamp='2026-09-25T12:00:00Z', event_type='WARNING', latitude=10.0, longitude=77.0,
                 zone='Test', risk_state='WARNING', ai_state='UNAVAILABLE', alert_state='Boundary warning')
    batch = {'device_id': 'test-device', 'events': [event]}
    for _ in range(2):
        result = client.post('/api/v1/sync/batch', json=batch)
        assert result.status_code == 200, result.text
        assert result.json()['acknowledged_ids'] == ['event-1']
    status = client.get('/api/v1/sync/status/test-device').json()
    assert status['synced_events'] == status['total_breadcrumbs'] == 1
    with SessionLocal() as db:
        assert [alert.id for alert in db.query(Alert).all()] == ['event-1']

    # A conflict after a new event must roll back all of that batch's writes.
    new_event = {**event, 'event_id': 'event-2'}
    event['latitude'] = 11.0
    batch['events'] = [new_event, event]
    assert client.post('/api/v1/sync/batch', json=batch).status_code == 409
    with SessionLocal() as db:
        assert db.query(Device).count() == 1
        assert [row.event_id for row in db.query(SafetyEvent).all()] == ['event-1']
        assert db.query(LocationBreadcrumb).count() == 1
        assert [row.id for row in db.query(Alert).all()] == ['event-1']
        assert db.query(SyncReceipt).count() == 2

    # Correcting the conflict allows both the old event and the new event to sync.
    event['latitude'] = 10.0
    for _ in range(2):
        result = client.post('/api/v1/sync/batch', json=batch)
        assert result.status_code == 200, result.text
        assert result.json()['acknowledged_ids'] == ['event-2', 'event-1']
    status = client.get('/api/v1/sync/status/test-device').json()
    assert status['synced_events'] == status['total_breadcrumbs'] == 2
    with SessionLocal() as db:
        assert {row.id for row in db.query(Alert).all()} == {'event-1', 'event-2'}
