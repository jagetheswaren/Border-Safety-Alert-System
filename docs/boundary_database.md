# Offline Boundary Database (Phase 4)

## Architecture

```text
assets/boundaries/demo_boundaries.geojson
      ↓
parseBoundariesFromGeoJson (lib/services/boundary_import.dart)
      ↓
ensureDemoBoundariesSeeded (lib/services/boundary_seed.dart)
      ↓
BoundaryRepository (lib/services/boundary_repository.dart)
      ↓
AppDatabase (lib/database/app_database.dart)
      ↓
SQLite (border_safety.db, table `boundaries`)
      ↓
BoundaryModel (lib/models/boundary_model.dart)
```

Screens never execute SQL: Home reads a `Future<BoundarySummary>` through
`BoundaryCountCard`, loaded by `OfflineBoundaryProvider`
(lib/services/boundary_summary.dart). Widget tests inject
`FakeBoundarySummaryProvider` instead.

## Table schema (version 1)

```sql
CREATE TABLE boundaries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  risk_level TEXT NOT NULL,
  country TEXT,
  description TEXT,
  polygon_data TEXT NOT NULL,
  source TEXT,
  version TEXT,
  updated_at TEXT,
  enabled INTEGER NOT NULL DEFAULT 1
);
```

## BoundaryModel

Fields: `id, name, type, riskLevel, country, description, polygon, source,
version, updatedAt, enabled`. `type` is an open string set
(`international_border | forest | wildlife | military | mining | disaster |
coastal | restricted | custom`); `riskLevel` reuses the `RiskLevel` enum.
`toMap()`/`fromMap()` validate strictly and throw `FormatException` on bad
input — never silent defaults.

## Polygon serialization

`polygon_data` is a JSON string of GeoJSON-style rings:
`[[[lon, lat], ...], ...]`, outer ring first, then holes, per RFC 7946
`[longitude, latitude]` order. Dart doubles round-trip through JSON with
full precision (covered by test). Rings must be closed (first == last
position) and hold at least 4 positions; the importer rejects the rest.

## GeoJSON import

`parseBoundariesFromGeoJson` accepts a `FeatureCollection` of `Polygon`
features with `name`, `type`, `risk_level` (LOW|MEDIUM|HIGH) and optional
`country`, `description`, `source`, `version`, `updated_at`, `id`. Missing
ids fall back to a deterministic name slug (`"Demo Forest B"` →
`"demo-forest-b"`), so re-imports upsert the same row.

## Seed process

`ensureDemoBoundariesSeeded` inserts the bundled GeoJSON only when the table
is empty (returns the inserted count, 0 when skipped). Inserts use
`ConflictAlgorithm.replace`, so even a forced re-seed cannot duplicate rows.
An empty feature list raises `BoundaryException` instead of seeding nothing.

## Repository API

`insertBoundary` (upsert), `insertBoundaries` (batch upsert),
`getBoundaryById`, `getAllBoundaries`, `getEnabledBoundaries`,
`getBoundariesByType`, `updateBoundary`/`deleteBoundary`/`clearBoundaries`
(returning affected-row counts), `countBoundaries({enabledOnly})`.
Storage failures are wrapped in `BoundaryException` with the cause preserved.

## Demo-data limitations

Everything under `source: SYNTHETIC-DEMO-v0.1` is synthetic test geometry —
not authoritative borders. `BoundaryModel.isDemo` detects the marker, and
the UI labels it "Demo data — non-authoritative". Replace
`assets/boundaries/demo_boundaries.geojson` with a licensed dataset and a
matching `source`/`version` before any real-world use.

## How Phase 5 consumes this

Phase 5 (Geo-Fence engine) reads `getEnabledBoundaries()`, parses each
`polygon` into point-in-polygon / distance routines, and combines the result
with the Phase 3 GPS stream. No schema change is needed for that.
