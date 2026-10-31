"""Development-only simulated coordinate tests; never physical GPS evidence."""
import json
import pytest
from app.database import SessionLocal
from app.models.zone import Zone

@pytest.mark.parametrize('latitude,longitude,expected', [(10.15,78.15,'CRITICAL'), (10.099,78.15,'WARNING'), (11.0,79.0,'SAFE')])
def test_simulated_gps_risk(client, latitude, longitude, expected):
    with SessionLocal() as db:
        zone = Zone(id='gps-test-zone', name='SIMULATED TEST ZONE', type='RESTRICTED', severity='CRITICAL', enabled=True, warning_radius_m=500, geometry=json.dumps({'type':'Polygon','coordinates':[[[78.1,10.1],[78.2,10.1],[78.2,10.2],[78.1,10.2],[78.1,10.1]]]}))
        db.add(zone)
        db.commit()
    response = client.post('/api/v1/geofence/check', json={'latitude':latitude,'longitude':longitude})
    assert response.status_code == 200
    result = response.json()
    assert result['risk'] == expected
    assert result['nearest_zone_id'] == 'gps-test-zone'
    assert result['distance_m'] >= 0

@pytest.mark.parametrize('latitude,longitude', [(91,78),(10,181),(-91,78)])
def test_reject_invalid_gps(client, latitude, longitude):
    assert client.post('/api/v1/geofence/check', json={'latitude':latitude,'longitude':longitude}).status_code == 422

def test_gps_check_requires_authentication(anonymous):
    assert anonymous.post('/api/v1/geofence/check', json={'latitude':10,'longitude':78}).status_code == 401


def test_alert_recording_is_explicit_and_cooled_down(client):
    from app.models.alert import Alert
    with SessionLocal() as db:
        db.add(Zone(id='consent-zone', name='SIMULATED TEST ZONE', type='RESTRICTED', severity='CRITICAL', enabled=True, warning_radius_m=500, geometry='POLYGON((78.1 10.1,78.2 10.1,78.2 10.2,78.1 10.2,78.1 10.1))'))
        db.commit()
    position = {'latitude':10.15,'longitude':78.15,'accuracy_m':10}
    assert client.post('/api/v1/geofence/check', json=position).json()['alert_id'] is None
    with SessionLocal() as db:
        assert db.query(Alert).count() == 0
    first = client.post('/api/v1/geofence/check', json={**position,'record_alert':True}).json()
    second = client.post('/api/v1/geofence/check', json={**position,'record_alert':True}).json()
    assert first['risk'] == 'CRITICAL'
    assert first['alert_id'] == second['alert_id']
    with SessionLocal() as db:
        assert db.query(Alert).count() == 1
        assert db.query(Alert).first().user_id is not None


def test_inaccurate_location_does_not_claim_safe_or_record_alert(client):
    from app.models.alert import Alert
    response = client.post('/api/v1/geofence/check', json={'latitude':10.15,'longitude':78.15,'accuracy_m':201,'record_alert':True})
    assert response.json()['risk'] == 'UNKNOWN'
    with SessionLocal() as db:
        assert db.query(Alert).count() == 0


def test_field_user_cannot_record_operator_alerts(client):
    from app.models.user import User
    with SessionLocal() as db:
        db.query(User).filter(User.email == 'operator@example.test').first().role = 'FIELD_USER'
        db.commit()
    assert client.post('/api/v1/geofence/check', json={'latitude':10.15,'longitude':78.15,'record_alert':True}).status_code == 403
