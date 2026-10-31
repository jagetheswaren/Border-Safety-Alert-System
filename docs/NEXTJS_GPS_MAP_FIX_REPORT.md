# Next.js map and GPS repair — 24 October 2026

Scope: existing Next.js app and necessary FastAPI integration. Android/Flutter files were not changed for this task. Existing unrelated workspace changes were preserved.

## Implementation

- The active map route uses BSASMap, not the older MapComponent. The key-free map uses existing Leaflet/react-leaflet packages and OpenStreetMap street tiles, with Esri satellite/hybrid imagery and attribution. Google Maps remains optional. No dependencies added.
- Definite map height, ResizeObserver, mobile toolbar, visible zoom controls, drag/recenter and tile-error messages.
- Real getCurrentPosition and watchPosition calls, high-accuracy request, explicit start/stop/retry, coordinates, reported accuracy, blue marker and accuracy radius. Repeated starts replace the watcher. Stopped sessions reject late callbacks. Stale readings expire after 30 seconds; a 20-second watchdog handles stalled browser requests.
- Permission denial, timeout, unavailable position, unsupported browser and insecure-context handling. No background-browser tracking or guaranteed hardware precision is claimed.
- Fresh positions go to authenticated POST /api/v1/geofence/check. The UI displays backend risk, zone and distance. Missing/stopped/stale location or API failures produce UNKNOWN. This is a read-only evaluation: no new location storage, broadcasting or dispatch-alert creation was added.
- API failures are visible instead of silently becoming empty arrays. Map hooks share the authenticated API client. Refresh updates map overlays and header counts.
- Fixed actual backend WKT POLYGON geometry being incorrectly parsed as JSON. Validated WKT/GeoJSON parsing preserves longitude/latitude order, zero coordinates and holes. Zone overlays now come from the same backend dataset used for geofencing.
- Boundary lines remain labelled unverified for navigation. No official coordinates were invented. Legend distances no longer claim fixed example thresholds.

## Modified files

Frontend:

- src/app/dashboard/map/page.tsx
- src/app/globals.css
- src/lib/api.ts
- src/features/map/hooks/useCurrentLocation.ts
- src/features/map/hooks/useBorders.ts
- src/features/map/hooks/useIncidents.ts
- src/features/map/components/BSASMap.tsx
- src/features/map/components/OfflineMapView.tsx (existing name retained; online Leaflet tiles)
- src/features/map/components/LocationSafetyPanel.tsx (new)
- src/features/map/components/MapToolbar.tsx
- src/features/map/components/MapLegend.tsx
- src/features/map/components/SafetyZoneLayer.tsx
- src/features/map/types/map.types.ts
- src/features/map/services/zoneGeometry.ts (new)
- scripts/test-zone-geometry.cjs (new)

Other:

- backend/tests/test_geofence_gps.py (new)
- scripts/browser_gps_fixture.js (new, localhost-only test fixture; never imported by app)

## Testing

| Status | Check | Evidence and limits |
|---|---|---|
| PASSED | Production build | Compiled and generated 21 routes; benign parent package-lock warning |
| PASSED | TypeScript and scoped ESLint | Changed map/API files checked |
| PASSED | Backend tests | 29 passed; six dependency deprecation warnings; isolated database |
| PASSED | Geometry regression | Legacy WKT, GeoJSON, zero coordinates, holes and six malformed cases |
| PASSED | Visible real map | Roads, towns, configured lines and attribution inspected in browser; 12 loaded OSM tiles |
| PASSED | Native permission request | Browser reached granted permission in secure localhost context |
| NOT VERIFIED | Actual physical coordinates | No physical fix returned by this browser/device; simulated coordinates are not physical GPS evidence |
| PASSED | Live marker, accuracy and risk | Labelled simulated readings; real authenticated backend returned SAFE, WARNING and CRITICAL against existing zones |
| PASSED | Start/stop/retry and late callback | One watcher after repeated starts, zero after stop; late result ignored; UNKNOWN on stop |
| PASSED | Denied/timeout/recovery | Labelled browser fixture; denial clears watcher; recovery restores evaluation |
| PASSED | Stale reading | After 30 seconds without a fix, current location disappears and safety becomes UNKNOWN |
| PASSED | API error handling | Aborted geofence and zone requests display errors instead of false SAFE or empty success |
| PASSED | Mobile layout | 390 x 844 viewport, document width 390; no horizontal overflow |
| NOT TESTED | Physical movement | Requires a real device/location service |
| NOT TESTED | Android Chrome, Edge and other browsers | Desktop Chromium automation and mobile viewport only |
| NOT TESTED | Optional Google services | Routes, traffic and Street View not validated with a Google key |

Development testing encountered a Turbopack hot-reload panic. The development process was stopped; final verification uses production build/start.

Final production verification: Next.js production server is running on port 3000 and the API on 8000. Final build, scoped lint and geometry regression checks passed. The normal browser page has no GPS test fixture, 24 loaded street tiles and no recorded page errors. Zoom controls were clicked, and dragging changed the Leaflet map-pane transform. Final production denial/recovery and CRITICAL/WARNING tests also passed with the labelled fixture, which was then removed by full navigation. The native laptop location request timed out; it was not replaced with a synthetic location in the ordinary app.

## Setup and run

Use two terminals from the project directory:

```powershell
cd backend
..\venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

```powershell
cd frontend
# Run npm ci only if dependencies are absent.
npm run build
npm run start -- --hostname 127.0.0.1 --port 3000
```

Open http://localhost:3000/dashboard/map and sign in with your existing account. Click Start Tracking / My Location, allow location permission, and enable device location services. The Flutter client at port 8080 is a different application surface.

Local frontend setting in frontend/.env.local: NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1. For hosted use, configure an HTTPS backend and explicit CORS origins. Localhost on a phone refers to the phone, not this laptop. Use an HTTPS deployment for cross-device testing; a laptop LAN HTTP address normally cannot provide secure-context browser geolocation.

Default Leaflet/OSM needs no Google key. Optional Google browser keys need origin/API restrictions. No new dependencies are required.

Run checks from project root:

```powershell
.\venv\Scripts\python.exe -m pytest backend/tests -q
node frontend/scripts/test-zone-geometry.cjs
```

## Screenshots

- output/nextjs-map-real.png — ordinary map without simulated coordinates
- output/nextjs-gps-real-request.png — native request, not physical fix evidence
- output/nextjs-gps-simulated-critical.png
- output/nextjs-gps-simulated-warning.png
- output/nextjs-map-mobile-simulated.png
- output/nextjs-gps-simulated-denied.png
- output/nextjs-gps-simulated-api-failure.png
- output/nextjs-gps-simulated-recovered.png
- output/nextjs-gps-simulated-stale.png
- output/nextjs-map-zone-api-failure.png

Simulated GPS screenshots carry a prominent SIMULATED GPS TEST banner. A full navigation removes the browser-only fixture; it is not bundled or loaded by application code.

## Remaining limits

Physical GPS/movement and cross-browser behavior need device testing. Boundary provenance is unverified. OSM public street tiles are online and best effort; bulk downloading/offline prefetch is not supported. Backend risk uses configured zones, not independently verified official boundaries. No emergency dispatch, guaranteed navigation safety or background-browser tracking is claimed.

References: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API and https://operations.osmfoundation.org/policies/tiles/ .
