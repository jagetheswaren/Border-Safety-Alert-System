# Phase 5 Geo-Fencing

The Phase 5 GeoFence engine is deterministic and does not use AI. It combines
the validated `LocationModel` from `GpsService` with enabled polygons read by
`BoundaryRepository`, then exposes one structured `GeoFenceResult` to the UI.

## Architecture

```text
GpsService -> LocationModel -> GeoFenceService -> GeoFenceResult -> Flutter UI
					   |
				   BoundaryRepository -> SQLite
```

`GeoFenceService` caches the enabled-boundary read for its lifetime. A future
refresh can call `refreshBoundaries()` after an import or settings change.

## Coordinate conventions

`LocationModel` stores decimal-degree `latitude` and `longitude` fields.
`BoundaryPosition` deliberately stores the same named fields, but serialized
GeoJSON uses RFC 7946 coordinate order: `[longitude, latitude]`. The importer
and model preserve this order; no caller should transpose a pair manually.

## Algorithms

Point-in-polygon uses ray casting in longitude/latitude space. Points on an
edge or vertex count as inside. The first ring is the outer ring and later
rings are holes. Empty, short, or non-finite rings are unusable and never
produce a safety result.

Distance to a polygon boundary uses a local equirectangular projection to find
the closest point on each segment, then calculates the final distance with a
haversine spherical-Earth calculation (`R = 6,371,000 m`). This is suitable
for the prototype's meter-to-kilometer areas, not survey-grade geodesy or
large polygons near the poles/dateline.

Bearing uses the initial great-circle bearing convention `0 = North`,
`90 = East`, `180 = South`, and `270 = West`, normalized to `[0, 360)`.
Movement difference is the smallest angular difference between GPS movement
bearing and bearing toward the closest boundary point, normalized to
`[0, 180]`. A difference of at most 45 degrees is exposed as moving toward.

## States and thresholds

States are `UNKNOWN`, `SAFE`, `CAUTION`, `WARNING`, `CRITICAL`, and
`INSIDE_RESTRICTED_AREA`. The default prototype thresholds are:

```text
caution:  1,000 m
warning:    300 m
critical:   100 m
```

`GeoFenceConfig` owns these values. State selection is deterministic: missing
location/data is `UNKNOWN`, an inside point is `INSIDE_RESTRICTED_AREA`, and
an outside point is classified by the nearest configured radius.

## Error handling

Invalid coordinates, malformed geometry, repository failures, and empty
enabled-boundary results return `UNKNOWN`. Failed calculations are represented
as `null`; they are never converted into a fabricated zero-meter distance.
Disabled boundaries are excluded before nearest-boundary selection.

## Testing

`test/geofence_service_test.dart` covers inside, outside, edge, near and far
points, invalid and empty polygons, meter distances, cardinal and wrap-around
bearings, every state, movement direction, disabled rows, and nearest enabled
boundary selection using SQLite FFI.

## Phase 6 alert integration and remaining limitations

`AppShell` passes the single `GeoFenceResult` from this service to Home, Map,
Safety, and `AlertService`. Phase 6 uses that existing result for the visual
alert banner and the optional voice, vibration, and notification channels;
`AlertService` performs no geographic calculation and creates no second GPS
stream.

The project still has no offline map tiles, safe routing, backend dependency,
or machine-learning component. Synthetic demo polygons remain
non-authoritative and are labeled in the UI. For larger datasets, add
bounding-box prechecks, regional partitioning, or an R-tree/spatial index
before evaluating every polygon.
