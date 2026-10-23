# BSAS Flutter Mobile Application — UI/UX Rebuild Audit

**Audit Date**: October 2026  
**Repository**: BSAS (Border Safety & Alert System) — Mobile App (`border_safety_alert`)  
**Baseline Test Results**: **116/116 tests passing (100%)**  
**Static Analysis**: **0 issues (`dart analyze` clean)**

---

## 1. Domain & Operational Capabilities Audit

| Subsystem | File / Component | Status | Notes |
| :--- | :--- | :--- | :--- |
| **Authentication / Session** | `lib/services/sync_service.dart`, `flutter_secure_storage` | **WORKING** | JWT storage, secure key storage, token refresh with FastAPI `/api/v1/auth/token`. |
| **GPS / GNSS Engine** | `lib/services/gps_service.dart`, `location_provider.dart` | **WORKING** | Geolocator-backed foreground GPS stream, accuracy monitoring, lock detection, mockable via `FakeLocationProvider`. |
| **Foreground Tracking** | `lib/services/tracking_service.dart` | **WORKING** | Location fix buffer, distance accumulation, time/speed metrics, battery-safe foreground execution. |
| **Online / Offline Mapping** | `lib/screens/map_screen.dart`, `offline_map_service.dart`, `offline_tile_provider.dart` | **WORKING** | Dual-mode: FlutterMap raster tiles (with embedded asset offline tiles up to Z12) and online OSM fallback. |
| **Authoritative Geofencing** | `lib/services/geofence_service.dart`, `geo_math.dart` | **WORKING** | Spherical ray-casting, geodesic point-to-polygon distance, 3-tier boundary corridors (Safe, Caution, Warning, Critical). |
| **Risk Engine Fusion** | `lib/services/risk_engine.dart` | **WORKING** | Fuses spatial geofence proximity with on-device machine learning predictions. |
| **Local AI (TFLite)** | `lib/services/ai_prediction_service.dart`, `assets/models/phase7-lstm-v1.tflite` | **WORKING** | On-device LSTM trajectory classification with pure fallback heuristic if C-API binary is missing on non-mobile host. |
| **Multimodal Alerts** | `lib/services/alert_service.dart`, `alert_preferences_store.dart` | **WORKING** | Unified pipeline triggering Audio, Voice (TTS), Vibration, and OS-level Local Notifications. |
| **Voice Alerts (TTS)** | `lib/services/voice_alert_service.dart`, `flutter_tts` | **WORKING** | Text-to-speech engine with queue handling and rate/pitch controls. |
| **Tactile Feedback** | `lib/services/vibration_alert_service.dart`, `vibration` | **WORKING** | Dynamic vibration patterns (short pulses for caution, continuous bursts for perimeter breaches). |
| **System Notifications** | `lib/services/notification_service.dart`, `flutter_local_notifications` | **WORKING** | High-priority Android notification channels for critical border warnings. |
| **Local Event Store (SQLite)**| `lib/database/app_database.dart`, `local_event_store.dart`, `sqflite` | **WORKING** | SQLite persistence for incursion logs, offline boundary summaries, and sync queue. Host tests backed by `sqflite_common_ffi`. |
| **Reconnection Sync** | `lib/services/sync_service.dart` | **WORKING** | Exponential backoff, reconciliation queue, dual-direction push/pull with FastAPI endpoints. |
| **Local LLM / Chat** | `lib/services/local_chat_service.dart`, `ollama_ai_provider.dart`, `chat_memory_service.dart` | **WORKING** | On-device Ollama connection with context-aware safety prompt building and memory buffers. |
| **A-to-B Route Planning** | `lib/services/routing_service.dart`, `screens/route_screen.dart` | **WORKING** | Graph-based safety path-finding away from active restricted zones. |

---

## 2. UI / UX Audit: Current vs React Bits Design Language

| Screen / Widget | Current Implementation | Rebuild Goal (React Bits Native) | Target State |
| :--- | :--- | :--- | :--- |
| **Splash Screen** | Basic timer + logo display | Tactical radar-sweep, BSAS emblem entrance, system diagnostics check, 1.5s snappy handoff. | **REBUILT** |
| **App Shell / Navigation** | Standard Flutter `NavigationBar` | Elevated floating dock navigation with sliding pill selection indicator, subtle icon shifts, zero reload tab persistence. | **REBUILT** |
| **Home Screen** | Bespoke Sliver screen with status | Primary Hero Safety Card with touch-spotlight (`BSASCard`), dynamic border feedback (`BSASElectricBorder`), live CountUp metrics, and `BSASSlideButton`. | **REBUILT** |
| **Live Map Screen** | FlutterMap with controls | Dominant edge-to-edge canvas, floating GlassPanel (`BSASGlassPanel`), vertical dock controls, pulse GPS marker, and draggable bottom status sheet. | **REBUILT** |
| **Incidents & History** | Simple ListView | AnimatedList with fade-and-slide entry, filter pill tabs (`BSASPillNav`), and interactive detail bottom sheet. | **REBUILT** |
| **Alerts Screen** | Standard cards | Critical alert electric glowing border, tactile acknowledge slide action with morphing state (Idle -> Loading -> Confirmed). | **REBUILT** |
| **Route Planner** | Basic input form | Tactical glass routing sheet, distance/ETA count-up, waypoint guidance away from danger corridors. | **REBUILT** |
| **AI / Risk Status** | Chat interface | Transparent visual risk pipeline (GNSS -> Geofence -> LSTM / Rule Engine -> Risk Classification -> Alert Broadcast). | **REBUILT** |
| **Settings Screen** | Standard ListTiles | Tactical segmented controls for alerts (Voice, Vibration, Notifications), map layer choices, and accessibility reduced-motion toggle. | **REBUILT** |

---

## 3. Baseline Verification Summary
- `flutter test`: **116 passed**, 0 failed.
- `dart analyze`: **0 issues**.
- Working backend and SQLite/TFLite layers are 100% preserved.
