# Privacy Policy & Data Governance — Border Safety Alert System (BSAS)

**Effective Date:** September 23, 2026  
**Application:** Border Safety Alert System (BSAS)  
**Package Name:** `org.bsas.bordersafety`  
**License:** MIT License  

---

## 1. Core Commitment: Zero Cloud Tracking

The Border Safety Alert System is an offline-first civilian life-safety application designed with privacy-by-design principles:
- **No Third-Party Advertising:** BSAS contains zero analytics SDKs, zero advertising brokers, and zero commercial tracking pixels.
- **No Remote Telemetry Mandate:** BSAS does not transmit your geographic coordinates to any external server during field monitoring.
- **Local On-Device Execution:** All geospatial mathematics, machine learning inference (LSTM + Random Forest), and generative AI processing execute strictly within your local device memory.

---

## 2. Information Collected & Processed

### 2.1 Geographic & GNSS Telemetry
- **Data Points:** Latitude, Longitude, Altitude, Velocity/Speed, Heading/Bearing, Accuracy radius, and Timestamp.
- **Purpose:** Continuous point-in-polygon border distance calculation and forward breach trajectory prediction.
- **Processing Location:** Evaluated purely on-device via the Android Location Manager / Hardware GNSS chip.
- **Storage:** Ephemeral sliding window of 5 past fixes in memory for LSTM feature extraction; optionally persisted in local device SQLite for audit logs.

### 2.2 Local Alert & Incident Logs
- **Data Points:** Event ID, timestamp, sector name, geofence state (`SAFE`, `CAUTION`, `WARNING`, `CRITICAL`), and alert delivery audit (sound, vibration, TTS).
- **Storage:** Persisted locally in your device's private SQLite application sandbox (`local_events.json` and SQLite `boundaries` database).

### 2.3 Local Generative AI Queries
- **Data Points:** Advisory safety prompts entered in the AI Assistant screen.
- **Processing:** Analyzed locally on-device by `Qwen3-0.6B-Q4_0.gguf` via the embedded llama.cpp runtime or a developer-hosted local Ollama instance (`127.0.0.1:11434`).
- **No Cloud Upload:** Prompts are never transmitted to commercial AI APIs (OpenAI, Anthropic, or cloud providers).

---

## 3. Optional Backend Synchronization

If an organization or field team connects BSAS to a self-hosted FastAPI instance:
- **Explicit Consent:** Synchronization is manually triggered or explicitly enabled in settings.
- **Transport Security:** All synchronization requires authenticated JSON Web Tokens (JWT) over TLS 1.3 / HTTPS encryption.
- **Data Minimization:** Only logged incident events (not continuous real-time breadcrumbs) are submitted for central dispatch coordination.

---

## 4. User Rights & Data Deletion

You retain absolute sovereignty over your safety data:
1. **One-Tap Data Purge:** Navigating to `Settings > Privacy & Data Governance` allows instant purging of all local SQLite audit logs, trip histories, and cached map tiles.
2. **Revocation of Permissions:** You can revoke Location or Notification permissions at any time via Android System App Settings.
3. **Application Uninstallation:** Uninstalling BSAS completely removes the local SQLite database and all cached assets from the Android private storage partition.

---

## 5. Contact & Security Reporting

For security disclosures or privacy inquiries:
- **GitHub Issues:** [jagetheswaren/Border-Safety-Alert-System/issues](https://github.com/jagetheswaren/Border-Safety-Alert-System/issues)
- **Security Policy:** See [`docs/SECURITY.md`](docs/SECURITY.md)
