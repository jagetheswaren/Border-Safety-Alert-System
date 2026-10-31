# IMPLEMENTATION_PLAN.md — Border Safety Alert System (BSAS) 2.0

## Sprints Roadmap (Mobile-Only Architecture)

### Sprint 1: Repository Audit & Verification Baseline (COMPLETED)
- [x] Full source code inspection across `lib/`, `backend/`, and `test/`.
- [x] Verify baseline tests: 153/153 Flutter tests passing.
- [x] Verify static analysis: 0 warnings via `flutter analyze`.
- [x] Verify backend tests: 32/32 pytests passing.
- [x] Remove Next.js web dashboard from active development scope.
- [x] Generate `PROJECT_STATUS.md` and `IMPLEMENTATION_PLAN.md`.

---

### Sprint 2: Mobile UI/UX & Navigation Modernization
- [x] Unify bottom navigation bar (`BSASBottomNav`) to integrate dedicated SOS & Contacts access.
- [x] Add high-contrast Emergency SOS quick access floating action button / banner on Home, Map, and Safety screens.
- [x] Enhance loading, empty, and offline error states across all screens.
- [x] Standardize color system (`BsasColors`), typography, and electric border status indicators.
- [x] Ensure 0 static analysis errors and 100% test suite stability.

---

### Sprint 3: Global GIS & Forest Intelligence Engine
- [x] Implement GIS dataset models and repositories (`gis_boundary_model.dart`, `gis_layer_service.dart`).
- [x] Distinguish two distinct feature categories:
  - `OFFICIAL_FOREST_BOUNDARY` (Authoritative national parks, tiger reserves, government wildlife sanctuaries).
  - `ESTIMATED_FOREST_COVER` (JRC/satellite modeled forest canopy coverage).
- [x] Add administrative layers: Country boundaries, State/Province, and District boundaries.
- [x] Layer control drawer with independent toggle switches, legend, and source attribution metadata.
- [x] Interactive polygon feature inspection dialog (source organization, publication date, legal status disclaimer).

---

### Sprint 4: Offline GIS & Regional Tile Caching Engine
- [x] Extend SQLite `AppDatabase` with `gis_features` and `offline_regions` tables.
- [x] Add regional tile downloader and bounding-box geometry cache.
- [x] Implement truthful offline status indicator (distinguishing between offline GPS, offline polygons, and offline map tiles).
- [x] Support zero-network boundary evaluations using locally persisted GeoJSON polygons.

---

### Sprint 5: One-Tap SOS Emergency Alert System (CORE USER FEATURE)
- [x] **Emergency Contacts Model & Repository** (`emergency_contact.dart`, `emergency_contacts_screen.dart`):
  - Add, edit, delete contacts, phone number validation (Indian +91 and international E.164 formats).
  - Active / inactive status toggle.
  - SQLite persistent storage in `AppDatabase`.
- [x] **One-Tap SOS Engine** (`sos_service.dart`, `sos_event.dart`, `sos_delivery.dart`):
  - Immediate emergency event creation with unique UUID.
  - GPS coordinate capture (latitude, longitude, accuracy radius, timestamp, Google Maps URL).
  - Labelled last-known location fallback if GPS is searching/unavailable.
  - Automated SMS engine (Android SMS platform channel / native SMS integration with composer fallback).
  - WhatsApp prefilled share workflow (`https://wa.me/` URI scheme with pre-populated emergency text & coordinates).
  - Per-recipient delivery tracking: `SUBMITTED`, `DELIVERED`, `FAILED`, `PENDING_RETRY`.
  - Offline persistence in SQLite: queues unsent alerts until cellular signal or network is available.
  - 5-second accidental activation cancellation countdown with voice & vibration confirmation.
- [x] **Dedicated SOS Screen** (`sos_screen.dart`):
  - Large pulsing red SOS button.
  - Emergency telemetry cards: GPS coordinates, accuracy, cellular signal state, active contacts count.
  - Live delivery matrix showing each contact's SMS and WhatsApp status.
  - Emergency event cancellation option with safe broadcast.

---

### Sprint 6: App-Wide AI Safety Orchestrator
- [x] Central `AiOrchestrator` service accessible across all screens.
- [x] Cross-screen telemetry context injection (GPS fix, geofence state, nearest boundary, active alerts, SOS status).
- [x] Voice interaction integration using `flutter_tts` for vocalized safety advisories.
- [x] Strict safety isolation: AI is advisory-only and cannot mutate deterministic risk states or cancel SOS events.
- [x] Multi-provider architecture: Local Ollama / Backend Gateway / On-device GGUF / Honest offline diagnostic.

---

### Sprint 7: Verification, Release Build & Mobile Transfer
- [x] Run `flutter analyze` — ensure 0 issues.
- [x] Run full `flutter test` suite — ensure all tests pass.
- [x] Run backend pytest suite — ensure 32/32 pass.
- [x] Build Android release APK via `flutter build apk --release`.
- [x] Package release APK into a `.zip` archive for easy distribution.
- [x] Provide exact USB cable connection and `adb install` instructions for immediate deployment to physical mobile devices.
