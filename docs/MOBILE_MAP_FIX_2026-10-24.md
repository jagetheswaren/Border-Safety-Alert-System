# Mobile map repair — 24 October 2026

User scope: blank/loading tiles, location/follow problems, and missing border lines/place labels in the Android app.

## Changes

- Default street layer now uses labelled OpenStreetMap tiles with Esri street fallback. Native cache files for the previous Esri-only offline layer are no longer mixed into the new street layer.
- Existing satellite/hybrid modes retained. Explicit offline mode continues using existing Esri cached tiles, with native zoom capped to the dataset's level 13 rather than requesting absent higher-zoom tiles.
- Network tiles use flutter_map's existing built-in caching and normal interactive viewport requests. No OSM bulk download or offline-prefetch feature was added. Source attribution is visible above the bottom navigation.
- Live user marker is no longer surrounded by old alert pins by default. Alert history is retained and its map overlay can be re-enabled in Map Layers.
- Camera updates wait until the map is ready. Fresh fixes follow correctly; stale/invalid fixes cannot move the camera or appear as the current marker. A newly selected history target is handled after initialization too.
- Accuracy radius uses the actual reported value, without a false 1,000 m cap or invented minimum. Missing accuracy is labelled unknown.
- Zoom buttons now match map limits (2–19) instead of stopping at level 6. Native side controls can scroll in shorter screens.
- Added Show configured boundaries control. It fits the nearest configured polygon together with the user's actual position (or all loaded geometry if there is no nearest zone), then switches to free view so the next GPS update does not undo it.
- Tile/zone/border loading errors are visible, with Retry map action. Data errors no longer disappear silently.
- Connectivity timers cannot be created after the map screen is disposed; externally supplied services are not disposed by the map.
- Existing zero-latitude/longitude alert positions are valid and no longer rejected solely because a coordinate equals zero.
- USB updater also clears imported read-only build/asset attributes before building, resolving the observed Windows Gradle cleanup blocker without deleting assets or application data.

## Validation

- Static analysis of map and regression test: no issues.
- Three new widget regressions passed: correct street provider and world zoom; fitting configured boundaries without GPS recenter undo; fresh GPS follow and stale-position rejection.
- Full Flutter suite: **150 tests passed**. Intercepted network/tile warnings and unavailable Windows TFLite runtime messages during widget tests do not establish live tile delivery; device screenshots are used for that.
- Initial APK build hit read-only merged-asset directories. Their read-only attributes were cleared and a clean retry was started. Final build/install/device results are recorded below.

Files: `lib/screens/map_screen.dart`, `test/map_controls_regression_test.dart`, `scripts/update_android_usb.ps1`.

Limitations: configured polygons/lines are project data, not independently verified official international/maritime boundaries. Public online tiles require a connection and do not guarantee labels for every village at every scale. Cached offline coverage remains limited to the regions already prepared.

## Final installed-device results

- Final release APK build passed, about 508.7 MB. USB installation returned Success and opened the app, preserving existing data.
- On the physical Samsung phone, OpenStreetMap tiles visibly loaded roads, local place names and buildings. The location marker was clear and reported accuracy updated from approximately ±32 m to ±12 m.
- Recenter was tapped: the actual location moved to the map centre and follow mode became active.
- The configured-boundary action was tapped: configured polygons/lines appeared in a wider view and follow mode switched off. Subsequent wider map inspection showed country/town labels including the India–Sri Lanka region; the overlays remain configured project data.
- Reviewed post-interaction BSAS process logs contained no matching fatal, unhandled-exception or layout-overflow error.
- Evidence: `output/map-fix-street-phone.png`, `output/map-fix-recenter-phone.png`, `output/map-fix-boundaries-phone.png`, `output/map-fix-final-phone.png`.
- Phone left on the map, recentered to its actual location. No simulated phone positions were used.
