import hashlib
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from geoalchemy2.elements import WKTElement
from app.dependencies import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.models.device import Device
from app.models.sync import SafetyEvent, SyncReceipt
from app.models.alert import Alert
from app.models.location import LocationBreadcrumb
from app.schemas.sync import SyncBatchRequest, SyncBatchResponse
from app.database import is_postgres

router = APIRouter()

@router.post('/batch', response_model=SyncBatchResponse)
def sync_batch(request: SyncBatchRequest, db: Session = Depends(get_db),
               user: User = Depends(get_current_user)):
    try:
        if is_postgres:
            db.execute(text('SELECT pg_advisory_xact_lock(hashtext(:device))'), {'device': request.device_id})
        device = db.query(Device).filter(Device.device_identifier == request.device_id).first()
        if device and device.user_id != user.id:
            raise HTTPException(403, 'Device belongs to another account')
        if device is None:
            device = Device(device_identifier=request.device_id, user_id=user.id)
            db.add(device)
            # Breadcrumbs reference devices.id, not the client's device identifier.
            # Flush the parent first; SessionLocal has autoflush disabled.
            db.flush()
        if not device.is_active:
            raise HTTPException(403, 'Device is disabled')
        device.last_seen = datetime.now(timezone.utc)
        acknowledgements = []
        for item in request.events:
            payload = json.dumps(item.model_dump(mode='json', exclude={'device_id'}), sort_keys=True, separators=(',', ':'))
            digest = hashlib.sha256(payload.encode()).hexdigest()
            existing = db.get(SafetyEvent, item.event_id)
            if existing:
                if existing.device_id != device.id or existing.user_id != user.id or existing.payload_sha256 != digest:
                    raise HTTPException(409, 'Event ID conflicts with previously stored data')
                # The event and its side effects committed together; only acknowledge retries.
                acknowledgements.append(item.event_id)
                continue
            db.add(SafetyEvent(event_id=item.event_id, device_id=device.id, user_id=user.id,
                payload_json=payload, payload_sha256=digest, captured_at=item.timestamp))
            geom = WKTElement(f'POINT({item.longitude} {item.latitude})', srid=4326) if is_postgres else None
            db.add(LocationBreadcrumb(device_id=device.id, user_id=user.id, timestamp=item.timestamp,
                latitude=item.latitude, longitude=item.longitude, geom=geom))
            if item.risk_state in ('CRITICAL', 'WARNING', 'HIGH', 'INSIDERESTRICTEDAREA'):
                db.add(Alert(id=item.event_id, user_id=user.id, device_id=device.id,
                    type=item.event_type, severity='CRITICAL' if item.risk_state == 'INSIDERESTRICTEDAREA' else item.risk_state,
                    title=item.alert_state, message=f'Boundary: {item.zone}',
                    location_lat=item.latitude, location_lng=item.longitude, geom=geom, created_at=item.timestamp))
            acknowledgements.append(item.event_id)
        receipt = SyncReceipt(device_id=device.id, user_id=user.id, batch_size=len(request.events),
            synced_events_count=len(acknowledgements), status='SUCCESS',
            client_timestamp=request.client_timestamp, server_timestamp=datetime.now(timezone.utc))
        db.add(receipt)
        db.commit()
        db.refresh(receipt)
        return SyncBatchResponse(synced_count=len(acknowledgements), acknowledged_ids=acknowledgements,
            receipt_id=receipt.id, server_timestamp=receipt.server_timestamp)
    except HTTPException:
        db.rollback()
        raise
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, 'Concurrent event or device conflict; retry the batch')
    except Exception:
        db.rollback()
        raise HTTPException(503, 'Database synchronization unavailable; retain pending events')

@router.get('/status/{device_id}')
def get_sync_status(device_id: str, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    device = db.query(Device).filter(Device.device_identifier == device_id, Device.user_id == user.id).first()
    if not device:
        raise HTTPException(404, 'Device not found')
    count = db.query(SafetyEvent).filter(SafetyEvent.device_id == device.id).count()
    return {'device_id': device_id, 'synced_events': count,
            'total_breadcrumbs': db.query(LocationBreadcrumb).filter(LocationBreadcrumb.device_id == device.id).count(),
            'last_sync_timestamp': device.last_seen, 'status': 'RECEIVED' if count else 'NO_EVENTS'}
