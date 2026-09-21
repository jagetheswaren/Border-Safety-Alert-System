# Boundary data (synthetic demo only)

All files under `boundary-data/sample/` are **synthetic demo polygons** for
development and unit tests. The Flutter app bundles its runtime copy at
`assets/boundaries/demo_boundaries.geojson`.

They are NOT authoritative legal borders, military data, or forest-survey
data. Any real-world deployment must replace them with a licensed,
authoritative dataset and record `source`, `version`, and `updated_at` per
boundary row (see `docs/boundary_database.md`).

## Implemented SQLite schema

The application stores imported boundaries in SQLite table `boundaries`:

```sql
CREATE TABLE boundaries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,       -- international_border|forest|wildlife|military|mining|disaster|coastal|restricted|custom
  risk_level TEXT NOT NULL, -- LOW|MEDIUM|HIGH
  country TEXT,
  description TEXT,
  polygon_data TEXT NOT NULL, -- JSON array of GeoJSON rings
  source TEXT,
  version TEXT,
  updated_at TEXT,
  enabled INTEGER NOT NULL DEFAULT 1
);
```

## Coordinate convention

GeoJSON and `polygon_data` use RFC 7946 position order:

```text
[longitude, latitude]
```

The importer accepts a `FeatureCollection` containing `Polygon` features,
requires closed rings, rejects malformed geometry, and preserves this order.
Do not transpose a coordinate pair to `[latitude, longitude]`. See
`docs/boundary_database.md` for import, validation, and seed behavior.
