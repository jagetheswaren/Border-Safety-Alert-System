# GPS / Location Service (Phase 3)

## Pipeline

```text
GPS permission
      ↓
Android location service
      ↓
GeolocatorProvider (lib/services/location_provider.dart)
      ↓
GpsService (lib/services/gps_service.dart)
      ↓
LocationModel (lib/models/location_model.dart)
      ↓
GpsSnapshot → Home / Map / Safety UI
```

## Design rules

- Foreground fixes only (`ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` in
  `android/app/src/main/AndroidManifest.xml`). No background permission.
- `high` accuracy, 5 m distance filter; 15 s cap on the one-shot fix.
- `LocationModel.validated` rejects latitude outside [-90, 90] and longitude
  outside [-180, 180]; negative speed/heading/accuracy become null (unknown).
  Altitude may be negative (below sea level).
- Every failure (disabled service, denied/permanently-denied permission,
  stream error, provider exception, missing plugin) becomes a descriptive
  `GpsSnapshot` — the UI never fabricates coordinates and never crashes.
- Fixes with accuracy radius > 50 m are flagged `poorAccuracy`; fixes older
  than 30 s are flagged `stale` (no polling timer yet — evaluated at emit).
- The service talks only to the `LocationProvider` interface, so tests inject
  fakes (`test/helpers/fake_location_provider.dart`) with no GPS hardware.

## UI wiring

- `AppShell` owns `GpsService` (injectable via `BorderSafetyApp(gpsService:)`),
  rebuilds via `ListenableBuilder`, passes the snapshot to Home/Map/Safety.
- Home shows the live `GpsLiveCard` (lat/lon/accuracy/speed/bearing/altitude)
  above the demo safety card. Map shows a live coordinate line (`map-gps-line`).
  Safety drives its GPS chip from the live state; risk content stays demo.
- Retry re-runs permission/service checks and replaces the stream subscription.

## Verification without a device

`flutter test` covers models, service states, and UI rendering with fakes.
On-device check (pending — no emulator/device connected): install
`build/app/outputs/flutter-apk/app-release.apk`, grant location permission,
confirm locked coordinates on Home, then deny permission and confirm the
honest denied state (no fabricated position).
