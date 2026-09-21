# Phase 4 API Contract

This document records the actual backend contract as verified on the current repository. Any missing capabilities required by the frontend must be implemented minimally in the backend before UI integration.

## 1. Health
- **METHOD**: `GET`
- **PATH**: `/health`
- **AUTH REQUIREMENT**: None
- **RESPONSE**: `{ "status": "ok", "phase": 2 }`

## 2. Authentication (Login)
- **METHOD**: `POST`
- **PATH**: `/api/v1/auth/login`
- **AUTH REQUIREMENT**: None
- **REQUEST BODY**: `application/x-www-form-urlencoded` (OAuth2 Password flow: `username`, `password`)
- **RESPONSE JSON SHAPE**: `{ "access_token": "token", "token_type": "bearer" }`
- **ERROR RESPONSE**: `400 Bad Request` or `401 Unauthorized`

## 3. Current User
- **METHOD**: `GET`
- **PATH**: `/api/v1/auth/me`
- **AUTH REQUIREMENT**: Bearer Token
- **RESPONSE JSON SHAPE**: `{ "id": "str", "email": "str", "role": "str", "is_active": true, "created_at": "datetime" }`

## 4. Dashboard Stats
- **METHOD**: `GET`
- **PATH**: `/api/v1/dashboard/stats`
- **AUTH REQUIREMENT**: Bearer Token
- **RESPONSE JSON SHAPE**: `{ "active_users": int, "open_incidents": int, "critical_alerts": int, "current_risk": "str" }`

## 5. Alerts
- **METHOD**: `GET`
- **PATH**: `/api/v1/alerts/`
- **AUTH REQUIREMENT**: Bearer Token
- **QUERY PARAMETERS**: `skip: int`, `limit: int`, `severity: Optional[str]`, `zone_id: Optional[str]`
- **RESPONSE JSON SHAPE**: `[ { "id": "str", "type": "str", "severity": "str", "title": "str", "message": "str", "created_at": "datetime", ... } ]`
- **MISSING**: Advanced filtering (status, date), pagination total count payload.

## 6. Incidents
- **METHOD**: `GET`
- **PATH**: `/api/v1/incidents/`
- **AUTH REQUIREMENT**: Bearer Token
- **QUERY PARAMETERS**: `skip: int`, `limit: int`
- **RESPONSE JSON SHAPE**: `[ { "id": "str", "title": "str", ... } ]`
- **MISSING**: Incident detail (`GET /api/v1/incidents/{id}`), advanced filtering (search, severity, status, category, zone, date range), pagination total count payload.

## 7. Zones (Map Data)
- **METHOD**: `GET`
- **PATH**: `/api/v1/zones/`
- **AUTH REQUIREMENT**: Bearer Token
- **QUERY PARAMETERS**: `skip: int`, `limit: int`
- **RESPONSE JSON SHAPE**: `[ { "id": "str", "name": "str", "coordinates": JSON, ... } ]`

## 8. Events (Polling)
- **METHOD**: `GET`
- **PATH**: `/api/v1/events/poll`
- **AUTH REQUIREMENT**: Bearer Token
- **QUERY PARAMETERS**: `since: Optional[str]` (ISO8601 timestamp)
- **RESPONSE JSON SHAPE**: `[ { "id": "str", "type": "INCIDENT|ALERT", "title": "str", "severity": "str", "timestamp": "datetime", "data": "str" } ]`
- **DATA FRESHNESS**: Incremental polling supported via `since`.

---
**Note:** Missing endpoints and filter supports will be added minimally to the FastAPI backend during the P1 implementation phase.
