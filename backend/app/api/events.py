import asyncio
import json
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import List, Optional, Set
from jose import jwt, JWTError

from app.dependencies import get_db
from app.config import settings
from app.database import SessionLocal
from app.models.incident import Incident
from app.models.alert import Alert
from app.models.user import User
from app.api.auth import require_operator

router = APIRouter()

# Active WebSocket subscriber registry
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.discard(websocket)

    async def broadcast(self, message: dict):
        dead_connections = set()
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception:
                dead_connections.add(connection)
        for dead in dead_connections:
            self.active_connections.discard(dead)

manager = ConnectionManager()

def validate_token_param(token: Optional[str], db: Session) -> Optional[User]:
    if not token:
        return None
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"],
                             options={"require_exp": True, "require_sub": True})
        email: str = payload.get("sub")
        if not email:
            return None
        user = db.query(User).filter(User.email == email).first()
        if user and user.is_active and user.role in ("ADMIN", "OPERATOR"):
            return user
    except JWTError:
        return None
    return None

def fetch_events_list(db: Session, since: Optional[str] = None):
    incidents_query = db.query(Incident)
    alerts_query = db.query(Alert)
    
    if since:
        try:
            since_dt = datetime.fromisoformat(since)
            incidents_query = incidents_query.filter(Incident.created_at >= since_dt)
            alerts_query = alerts_query.filter(Alert.created_at >= since_dt)
        except ValueError:
            pass
            
    recent_incidents = incidents_query.order_by(Incident.created_at.desc()).limit(20).all()
    recent_alerts = alerts_query.order_by(Alert.created_at.desc()).limit(20).all()
    
    events = []
    for inc in recent_incidents:
        events.append({
            "id": inc.id,
            "type": "INCIDENT",
            "title": inc.title,
            "severity": inc.severity,
            "timestamp": inc.created_at.isoformat() if inc.created_at else None,
            "data": inc.id
        })
        
    for alt in recent_alerts:
        events.append({
            "id": alt.id,
            "type": "ALERT",
            "title": alt.title,
            "severity": alt.severity,
            "timestamp": alt.created_at.isoformat() if alt.created_at else None,
            "data": alt.id
        })
        
    events.sort(key=lambda x: x["timestamp"] if x["timestamp"] else "", reverse=True)
    return events[:50]

@router.get("/poll", dependencies=[Depends(require_operator)])
def poll_events(since: Optional[str] = None, db: Session = Depends(get_db)):
    return fetch_events_list(db, since)

@router.get("/stream")
async def stream_events(token: Optional[str] = Query(None), limit: Optional[int] = Query(None)):
    """
    Server-Sent Events (SSE) streaming endpoint for real-time telemetry updates.
    Sends periodic heartbeat comments (: keepalive) and JSON event payloads.
    """
    with SessionLocal() as db:
        user = validate_token_param(token, db)
    
    if not user:
        async def error_stream():
            yield f"event: error\ndata: {json.dumps({'error': 'Unauthorized'})}\n\n"
        return StreamingResponse(error_stream(), media_type="text/event-stream", status_code=401)

    async def event_generator():
        last_check = datetime.now(timezone.utc).isoformat()
        try:
            with SessionLocal() as gen_db:
                events = fetch_events_list(gen_db)
            yield f"event: initial\ndata: {json.dumps(events)}\n\n"
            count = 1
            if limit and count >= limit:
                return
            
            while True:
                await asyncio.sleep(5)
                with SessionLocal() as gen_db:
                    new_events = fetch_events_list(gen_db, since=last_check)
                last_check = datetime.now(timezone.utc).isoformat()
                if new_events:
                    yield f"event: update\ndata: {json.dumps(new_events)}\n\n"
                else:
                    yield f": keepalive {int(datetime.now(timezone.utc).timestamp())}\n\n"
                count += 1
                if limit and count >= limit:
                    return
        except (asyncio.CancelledError, GeneratorExit):
            pass

    return StreamingResponse(event_generator(), media_type="text/event-stream")

@router.websocket("/ws")
async def websocket_events(websocket: WebSocket, token: Optional[str] = Query(None)):
    """
    Real-time authenticated WebSocket communication channel for dispatch events.
    Supports bi-directional heartbeats (ping -> pong) and immediate alerts push.
    """
    with SessionLocal() as db:
        user = validate_token_param(token, db)
    
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await manager.connect(websocket)
    # Send initial connection confirmation
    await websocket.send_json({
        "type": "CONNECTION_ESTABLISHED",
        "protocol": "BSAS_REALTIME_V1",
        "user": user.email,
        "role": user.role,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })

    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                msg_type = payload.get("type", "").upper()
                if msg_type == "PING":
                    await websocket.send_json({"type": "PONG", "timestamp": datetime.now(timezone.utc).isoformat()})
                elif msg_type == "REQ_EVENTS":
                    with SessionLocal() as req_db:
                        events = fetch_events_list(req_db)
                    await websocket.send_json({"type": "EVENTS_SNAPSHOT", "events": events})
            except json.JSONDecodeError:
                await websocket.send_json({"type": "ERROR", "detail": "Invalid JSON format"})
    except WebSocketDisconnect:
        manager.disconnect(websocket)

