# Dataset plan (Phase 9)

Phase 1 contains NO trajectory data — only the demo polygons in `boundary-data/sample/`.

## Planned synthetic trajectory types

safe, approaching, parallel, away, crossing, stationary, turning — each a time-ordered
sequence around test polygons.

## Schema (per point)

```text
trajectory_id, timestamp, latitude, longitude, speed, bearing
```

Labels derived in feature engineering (Phase 9): movement_direction, boundary_crossing.
Split train/val/test BY trajectory_id (never mix points of one trajectory across splits).

Real GPS tracks can later replace/augment synthetic data; pipeline must support both.
Clearly label synthetic vs real in all reports.
