# Mobile app bug check — 24 October 2026

Scope: installed Samsung SM-A127F app and its existing Flutter source. Earlier local changes were preserved.

## Bugs fixed

1. Disconnected AI could still display READY. It now reports OFFLINE when no usable provider/runtime is available; gateway failures update provider state.
2. Expired tokens acquired by the local development gateway were not refreshed. They are renewed once after a 401 and the request is retried. Explicit user tokens are never replaced by a development operator session. Bundled development login is restricted to localhost/emulator endpoints, not remote hosts.
3. Canceled AI requests could affect a later request through a shared HTTP client. Each generation now owns its client, and canceled/obsolete generations cannot emit late replies or close the active generation's client.
4. Missing boundary data incorrectly returned alreadySafe from routing. It now returns UNKNOWN. Stale, missing-accuracy, inaccurate, invalid-coordinate and malformed-boundary inputs cannot generate a safe-route claim. Disabled boundaries are excluded.
5. Long AI provider names and the generation badge crowded the phone header. Title/subtitle are limited to one line and the status badge moves below the title row on narrow screens.
6. Asynchronous chat initialization could update a disposed screen. Added mounted checks after storage operations.

Also found the USB reverse connection had reset and restored the backend port. This is a temporary USB connection, not a permanent internet AI endpoint.

## Checks

- Full Flutter suite: **147 tests passed** (previously 140).
- Focused regression run: **13 tests passed** covering token renewal, user-token preservation, remote credential protection, cancellation, routing and the 360-pixel offline AI header.
- Static analysis of changed production/test files: **no issues**.
- Release APK: **build passed**, about 508.6 MB.
- Backend health and local model health returned OK.
- Reviewed BSAS process logs showed no matching fatal, unhandled-exception or layout-overflow error in the inspected window. This is not proof that no latent bugs remain.
- Flutter widget tests report intercepted network tile warnings; real map availability is checked on the actual phone, not inferred from those warnings.

## Honest capability assessment

Core map, foreground GPS and local-gateway AI were demonstrated on this physical phone in the preceding session. The reported GPS accuracy was approximately ±12 m; this is a sensor estimate, not a guaranteed position error.

The app is **not fully production-complete**:

- Current AI requires the USB link and laptop API/model services. Reconnecting the cable may require restoring forwarding with `scripts/update_android_usb.ps1 -ConnectOnly`.
- Boundary datasets are configured project data without independently established official navigation provenance.
- Native automatic backend alert synchronization/account configuration remains unfinished; local alert handling and Next.js opt-in history upload are separate implementations.
- Background GPS, sustained walking/driving, actual sound/vibration/voice alerts and full network-outage recovery have not all been physically verified.
- The grid route algorithm avoids configured polygons but does not establish road, terrain, water or maritime navigability.

Changed files: `lib/services/backend_ai_provider.dart`, `lib/services/routing_service.dart`, `lib/screens/ai_chat_screen.dart`, `test/backend_ai_provider_test.dart`, `test/ai_chat_connection_ui_test.dart`, `test/routing_service_test.dart`.

## Installed-phone verification

- Patched APK installation returned **Success**. Android reports version 1.1.0, updated 24 October 2026 at 12:21:41 on the device clock.
- App started successfully; the reviewed new process logs contained no matching fatal/unhandled/layout error.
- Real phone GPS locked with reported accuracy approximately ±13 m. Home and map screens rendered.
- New live AI test prompt: “What does BSAS do? One short sentence.” A newly generated response appeared in the phone chat and the provider label changed to `local-qwen3.5-4b via BSAS Gateway`.
- Narrow AI header is visibly fixed: title/subtitle stay on one line and READY/GENERATING displays on a separate row.
- Existing chat history was retained. The screenshot contains older messages as well as the new test answer; older warnings are not current test results.
- Evidence: `output/mobile-bugfix-installed.png`, `output/mobile-bugfix-map.png`, `output/mobile-bugfix-ai.png`, `output/mobile-bugfix-ai-test.png`.

Final verdict: core foreground GPS, real map and connected AI work in this test. The app is not 100% complete or certified for navigation; the limitations above remain.
