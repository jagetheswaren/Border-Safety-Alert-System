# BSAS web app and USB Android update

24 October 2026. This report supersedes earlier status claims for the work below.

## Delivered

- Main web application: existing Next.js project, http://localhost:3000/dashboard/map.
- Real AI page: http://localhost:3000/dashboard/ai. A generated Qwen response was displayed in the actual browser, labelled `local-qwen3.5-4b` and `Generated AI response`.
- Updated native app installed on the USB-connected Samsung SM-A127F. Android reported version 1.1.0 and installation update time 24 October 2026, 11:15. The app was opened after a successful `adb install -r`; existing app data/chat history was retained.
- Real phone GPS was visibly locked with reported accuracy about ±12 metres, with the position marker on real street tiles. No simulated phone coordinates were injected.
- USB reverse connections for ports 8000 (backend/AI) and 3000 (web). The native app is built with `BSAS_API_URL=http://127.0.0.1:8000` for this USB setup.
- Original Flutter project retained; the Flutter browser build also remains available at port 8080, but Next.js is the primary web app requested by the master prompt.

## Feature status

| Feature | Status | Verification / limitation |
|---|---|---|
| Interactive web map | WORKING | Leaflet with OSM street tiles, Esri satellite/hybrid, labels, attribution, zoom/drag/recenter; actual browser screenshots |
| Configured boundary lines | WORKING | Existing project GeoJSON rendered; labelled unverified for navigation |
| Safety-zone polygons | WORKING | Backend WKT and GeoJSON parsed correctly, preserving longitude/latitude order and holes |
| Browser live tracking | PARTIALLY WORKING | Real API request/permission path and watcher lifecycle verified; moving marker, errors and freshness tested with a labelled localhost fixture; desktop browser did not produce a physical fix |
| Native phone GPS | WORKING | Actual installed phone app displayed GPS lock, real marker and ±12 m reported accuracy; walking/movement test not performed |
| Geofence evaluation | WORKING | Authenticated same-origin POST, backend authoritative risk; >200 m reported accuracy yields UNKNOWN; last-update time displayed |
| Warning history sync | WORKING | Explicit opt-in saves server-calculated warnings with user/zone/location; server cooldown; isolated backend regression tests passed. Browser fixture did not write fake alerts into the live database |
| Visible safety warnings | WORKING | CRITICAL/WARNING/UNKNOWN displayed in real browser tests |
| Browser OS notifications | PARTIALLY WORKING | Explicit permission button and service-worker notification path implemented; actual OS delivery not tested |
| Web AI | WORKING | Genuine generated response observed through `/api/v1/ai/chat` same-origin proxy |
| Native AI connection | WORKING | USB backend connection, ready gateway and generated local-model replies observed in the phone UI; no secret cloud key bundled |
| AI fallback labelling | WORKING | Non-AI summaries are explicitly labelled as database fallback, never generated inference |
| PWA | PARTIALLY WORKING | Manifest, 192/512 PNG icons, activated service worker and Install BSAS prompt verified. Actual OS installation not completed during this test |
| Offline handling | PARTIALLY WORKING | Offline browser emulation shows connection-unavailable and no confirmed safety status. Service worker does not cache private APIs, GPS, AI responses or map tiles; offline maps are not claimed |
| Mobile responsive web | WORKING | 390 × 844 viewport; no horizontal overflow; AI and map screenshots |
| Physical Android Chrome / Safari / Edge web GPS | NOT TESTED | Desktop Chromium/mobile viewport testing is not a physical mobile-browser test |
| Native background GPS | NOT TESTED | No background tracking claim; keep the app active for current verified behavior |
| Official boundary provenance | BLOCKED | Existing configured datasets have not been independently verified as official international/maritime navigation boundaries |
| Antigravity environment | NOT TESTED | Not exposed by available tools; actual Chromium browser automation was used |

## Tests and builds

- Backend: **32 passed**, including explicit consent, alert cooldown, role restrictions, inaccurate GPS, coordinate validation and SAFE/WARNING/CRITICAL classification. Six dependency deprecation warnings.
- Flutter: **140 tests passed**; `flutter analyze --no-pub lib/` reported no issues.
- Flutter release web build passed.
- Android release APK build passed; installation returned **Success**. Earlier Windows read-only build-folder failures were corrected before the successful build.
- Next.js TypeScript and scoped ESLint passed. Final production build passed, generating 23 routes including AI, API proxy and manifest. The unrelated parent lockfile warning remains benign.
- Geometry regression script passed: legacy WKT, GeoJSON, holes, zero coordinates and malformed input.
- Production Next.js server, FastAPI, local model and optional Flutter browser server were left running on loopback.
- Latest local implementation was compared with GitHub main using fetch/diff. Remote main substantially differed and lacked several local integrations. No checkout, reset, merge or overwrite of the working tree was performed.

## Main implementation files

Web map and safety:

- `frontend/src/app/dashboard/map/page.tsx`
- `frontend/src/features/map/hooks/useCurrentLocation.ts`
- `frontend/src/features/map/hooks/useBorders.ts`
- `frontend/src/features/map/hooks/useIncidents.ts`
- `frontend/src/features/map/components/BSASMap.tsx`
- `frontend/src/features/map/components/OfflineMapView.tsx` (existing name retained; implementation now uses Leaflet online tiles)
- `frontend/src/features/map/components/LocationSafetyPanel.tsx`
- MapToolbar, MapLegend, SafetyZoneLayer, map types and `services/zoneGeometry.ts`
- `backend/app/api/geofence.py`
- `backend/tests/test_geofence_gps.py`

AI, PWA and connectivity:

- `frontend/src/app/dashboard/ai/page.tsx`
- `frontend/src/app/api/v1/[...path]/route.ts`
- `frontend/src/lib/api.ts`
- `frontend/src/app/manifest.ts`, `frontend/src/app/layout.tsx`
- `frontend/src/components/PwaSupport.tsx`
- `frontend/public/sw.js`, `frontend/public/icons/bsas-*`
- Sidebar, MobileNavigation and AppShell
- Local `.env.local` API URL set to `/api/v1`; no secret provider key was added to frontend configuration

Preserved mobile app / USB support:

- `lib/services/backend_ai_provider.dart`: configurable endpoint, browser same-origin default
- `lib/app.dart`: missing/stale GPS clears old safety status; obsolete async evaluations cannot overwrite new status
- `lib/screens/ai_chat_screen.dart`: stale GPS excluded from AI context, UNKNOWN default
- Existing real GPS retry/freshness fixes in GPS service, location provider and map
- `web/index.html`, `web/manifest.json`: browser metadata
- `scripts/serve_mobile_web.py`, `scripts/launch_bsas_web.py`
- `scripts/update_android_usb.ps1`

No new project npm/pip dependencies were required. Existing Leaflet, React Leaflet, Sharp and Flutter packages were reused. No paid service or billing was enabled.

## Start and use

Backend, from project root:

```powershell
cd backend
..\venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Web app, in a second terminal:

```powershell
cd frontend
npm run build
npm run start -- --hostname 127.0.0.1 --port 3000
```

Use your existing sign-in at http://localhost:3000. Map and AI are available through mobile navigation. Location sharing and saving location-bearing alerts are explicit user controls.

The AI model used here is the existing local Qwen3.5-4B server on port 1234. No cloud AI key is required for this configuration. Gemini/OpenAI secrets, if later configured, belong only in backend environment settings. Default Leaflet/OSM and device GPS need no map-provider key. Optional Google/MapTiler browser keys need origin restrictions; they are not secret AI credentials.

Rebuild and update the phone over USB:

```powershell
.\scripts\update_android_usb.ps1
```

Reconnect USB ports without rebuilding or reinstalling:

```powershell
.\scripts\update_android_usb.ps1 -ConnectOnly
```

Keep the cable connected and laptop API/model running for the phone's current AI endpoint. USB forwarding is temporary. The phone can open http://localhost:3000 over this reverse connection, but that phone-browser workflow was not tested while the user was actively using the native app. Normal non-USB mobile access requires a properly hosted HTTPS frontend/backend; the local development backend was not exposed publicly.

APK: `build/app/outputs/flutter-apk/app-release.apk`, approximately 508.6 MB. It is a local test artifact, not a verified app-store release.

## Evidence

- `output/android-updated-app.png`: installed physical app, real map and GPS lock
- `output/android-ai-screen.png`, `output/android-ai-live-test.png`: actual native AI UI; includes preserved older user history, not all messages are new test requests
- `output/nextjs-ai-real.png`: actual generated web AI answer
- `output/nextjs-ai-mobile.png`: responsive AI page
- `output/nextjs-final-mobile-map.png`: current responsive web map
- `output/nextjs-final-simulated-safety.png`: clearly labelled simulated coordinates, real backend CRITICAL response
- `output/nextjs-final-simulated-poor-accuracy.png`: clearly labelled simulation, UNKNOWN for ±250 m accuracy
- Earlier map/GPS regression screenshots are listed in `NEXTJS_GPS_MAP_FIX_REPORT.md`

Remaining user-facing limitations: official boundary verification, physical mobile-browser GPS/movement, OS notification delivery, cross-browser testing, actual PWA installation and hosted HTTPS deployment have not all been completed. No certified navigation, emergency dispatch or guaranteed background/offline map behavior is claimed.
