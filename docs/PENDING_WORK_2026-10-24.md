# Project pending-work audit — 24 October 2026

Scope: current Flutter browser app, shared mobile code, backend, and dashboard integration. Code inspection and local checks; no new physical GPS or emergency delivery test performed. Older percentage-complete and production-grade claims are not supported by this audit.

## Verified
- Full Flutter suite: 140 tests passed. Network tile warnings inside widget tests do not validate live map delivery.
- Flutter analysis of lib/: no issues.
- Latest Flutter release web build passed in preceding implementation turn.
- Local web, API and model ports listening (8080, 8000, 1234); API health reports development mode and connected SQLite; model health reports OK. Health is not proof of a successful inference this audit.
- Previous backend run in this session: 22 tests passed, six dependency deprecation warnings.

## Pending, in priority order
1. Validate geographic datasets. approved_boundaries.geojson and configured_lines.geojson claim an official BSAS survey but have no independently established authority/provenance. Verify intended border geometry, coordinate system, update process, and visual-line/geofence consistency before relying on warnings.
2. Fix unsafe routing outcomes. RoutingService returns alreadySafe when boundaries are empty. Grid A* avoids configured polygons but does not model real roads, terrain, water or navigability. Return unknown/unavailable on missing data and validate routes against the intended travel domain.
3. Complete GPS state propagation. Physical fix, moving-device follow, denied permission and recovery still need device testing. AI chat sets gpsAvailable from non-null location without checking stale; AppShell returns early when location is null, retaining the previous geofence result. Clear old safety state and reject stale location in routing/chat.
4. Wire backend synchronization. AppShell constructs SyncService but does not start it. SyncService uses dart:io HttpClient, unsuitable for browser requests, and release mode rejects the current local HTTP endpoint. Wire sign-in, endpoint settings, startup and event upload, then test server acknowledgements and dashboard receipt.
5. Implement browser persistence/offline mode. LocalEventStore depends on sqflite without a web factory; chat history depends on filesystem storage; OfflineMapService returns early on web. Add browser-compatible durable event/chat/tile storage and test reload plus network outage recovery.
6. Complete authentication/deployment. BackendAiProvider automatically logs in with embedded development operator credentials and defaults to loopback/emulator hosts. Wire real user sessions, remove bundled credentials, configure HTTPS/deployed endpoints, production secrets, explicit origins and intended production database. Launcher is laptop-specific. No public deployment verified.
7. Validate AI features independently. Local conversational model was previously demonstrated, but health alone does not prove current response quality. Web LstmRunner explicitly returns unavailable; browser trajectory LSTM inference is not implemented. Validate RF/model metrics, safety grounding, latency, failure behavior, and fresh telemetry.
8. Implement/verify background and emergency flows. Android manifest contains foreground location permissions, no background-location permission or declared foreground location service. HelpScreen is informational (only back action), not an SOS transmission flow. Verify sound, notifications, vibration and voice on real target devices.
9. Finish release verification. Rebuild/install latest Android app if mobile is in scope. Test actual boundary approach with controlled fixtures, offline recovery, route failures, narrow screens, browser permissions and end-to-end alert/sync flows. Next.js dashboard was not revalidated in this audit and is not currently listening on port 3000.
10. Correct project documentation. README and older audits claim full offline operation, official boundaries, background monitoring and emergency integrations beyond verified implementation. Publish platform-specific capabilities and limitations.

No application code changed during this audit.
