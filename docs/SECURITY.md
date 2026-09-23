# Security Architecture & Hardening Guide — Border Safety Alert System (BSAS)

**Classification:** Safety-Critical Civilian Telemetry & Defense In Depth  
**Version:** 1.1.0  
**Last Audited:** September 23, 2026  

---

## 1. Security Principles & Threat Model

BSAS operates on zero-trust, privacy-first principles designed to protect civilian users in sensitive border zones:
1. **Advisory AI Isolation:** The local Generative AI model (`Qwen3-0.6B`) is strictly sandboxed. It receives an immutable, read-only telemetry snapshot (`SafetyContextSnapshot`). It has **zero execution authority** over the deterministic geofencing engine, hardware sirens, or system files.
2. **Deterministic Risk Authority:** Geofence evaluations and ML trajectory assessments are deterministic. No conversational prompt, network injection, or LLM hallucination can alter an active `CRITICAL` or `WARNING` boundary breach state.
3. **No Hardcoded Secrets:** All backend JWT keys, database credentials, and service tokens are injected via environment variables. Committed code is scanned to ensure zero credential leakage.

---

## 2. Authentication & Authorization Hardening

### 2.1 Password Hashing
- **Algorithm:** `bcrypt` (Blowfish-based cipher with configurable work factor).
- **Implementation:** `passlib.context.CryptContext(schemes=["bcrypt"], deprecated="auto")`.
- **Validation:** Minimum 8 characters, requiring numeric and uppercase complexity. Mock/plain-text password verification is strictly prohibited.

### 2.2 JWT Cryptographic Token Security
- **Algorithm:** `HS256` (HMAC with SHA-256).
- **Secret Key:** Validated at application boot. The server will refuse to start if `SECRET_KEY` is empty, default (`"secret"`), or shorter than 32 characters in production environments.
- **Expiration:** Access tokens are strictly time-bounded (default 60 minutes) to prevent replay attacks.
- **Token Verification:** Every protected endpoint (`/api/v1/zones`, `/api/v1/events`, `/api/v1/sync`) enforces `HTTPBearer` header extraction and signature verification.

---

## 3. Network Transport & API Defense

### 3.1 Strict Cross-Origin Resource Sharing (CORS)
- Production deployments explicitly constrain allowed origins to designated operations dashboard hostnames (e.g., `https://dashboard.bsas.org`). Wildcard (`"*"`) origins are disallowed in production configuration.

### 3.2 Network Security Configuration (`network_security_config.xml`)
- Android release builds enforce HTTPS-only cleartext traffic policies.
- Insecure plain HTTP traffic (`http://`) is blocked by default across all domain routes except local loopback development bridges (`127.0.0.1`, `10.0.2.2`).

### 3.3 Rate Limiting & Input Validation
- **Pydantic Schemas:** All incoming JSON payloads (e.g., coordinates, boundary polygons, user registration) are strictly typed and bounded. Coordinates outside `-90.0 <= lat <= 90.0` or `-180.0 <= lon <= 180.0` are rejected immediately with HTTP 422.
- **SQL Injection Prevention:** All SQL persistence uses parameterized SQLAlchemy ORM queries and SQLite prepared statements. Raw string concatenation is prohibited.

---

## 4. Mobile & Device-Level Hardening

### 4.1 Local Storage Sandbox
- SQLite database (`boundaries.db`) and event audit files (`local_events.json`) reside exclusively in the Android internal app-private data directory (`/data/user/0/org.bsas.bordersafety/`).
- External SD card storage is never used for unencrypted safety event logs.

### 4.2 Minimal Android Permissions
BSAS requests only essential hardware permissions:
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` (geofencing evaluation)
- `POST_NOTIFICATIONS` (system alert delivery)
- `VIBRATE` (haptic alert feedback)
- `INTERNET` (optional map tile and sync retrieval)
Zero extraneous permissions (SMS, Contacts, Microphone, Camera, Phone State) are included in `AndroidManifest.xml`.

---

## 5. Security Audit Checklist

| Control | Mechanism | Verification Method | Status |
| :--- | :--- | :--- | :--- |
| **Password Hashing** | bcrypt with salt | Unit test with 10 random hashes | **PASS** |
| **Secret Scanning** | Git grep for keys/tokens | Automated scan across all tracked files | **PASS** |
| **SQL Injection** | SQLAlchemy ORM & parameterized queries | Code audit of repository queries | **PASS** |
| **AI Isolation** | Read-only context snapshot | Verified in `local_chat_service.dart` | **PASS** |
| **CORS Policy** | Restricted origin list in FastAPI | Backend middleware configuration test | **PASS** |
| **Cleartext Blocking** | `network_security_config.xml` | Release manifest audit | **PASS** |
| **Dependency CVEs** | Dart analyze, pip audit, npm audit | CI workflow dependency inspection | **PASS** |
