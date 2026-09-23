# BSAS Offline Map & Pre-Caching Architecture

## 1. Overview
In border, maritime, and rural corridors, cellular data connectivity is often intermittent or completely absent. BSAS provides an offline-first raster tile engine built on top of `flutter_map` and a custom `OfflineTileProvider`.

---

## 2. Architecture & Tile Flow

```text
PRE-DEPLOYMENT:
┌─────────────────────────┐
│     Internet Online     │
│   OpenStreetMap Server  │
└────────────┬────────────┘
             │ Rate-limited download (cache_offline_map.py)
             ▼
┌─────────────────────────┐
│   Local Tile Storage    │
│   • {z}/{x}/{y}.png     │
│   • manifest.json       │
└────────────┬────────────┘
             │ ADB push / app installer
             ▼
FIELD DEPLOYMENT (ZERO INTERNET):
┌─────────────────────────┐
│     Device Storage      │
│   offline_tiles/        │
└────────────┬────────────┘
             │ FileImage read
             ▼
┌─────────────────────────┐
│   OfflineTileProvider   │
│   (Local file fallback) │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  FlutterMap Renderer    │
│  • GPS Pulse Marker     │
│  • Trail Polyline       │
│  • Geofence Boundaries  │
└─────────────────────────┘
```

---

## 3. Pre-Caching Script (`scripts/cache_offline_map.py`)

A developer utility is provided to pre-cache tiles for designated operational corridors.

### Usage
```powershell
# 1. Preview tile count (dry run)
.\venv\Scripts\python.exe scripts/cache_offline_map.py --dry-run

# 2. Pre-cache designated sector (e.g. Pollachi / Coimbatore corridor, zoom 8-12)
.\venv\Scripts\python.exe scripts/cache_offline_map.py --delay 0.15

# 3. Verify cache integrity and checksum
.\venv\Scripts\python.exe scripts/cache_offline_map.py --verify-only
```

### OSM Compliance Safeguards
- Custom User-Agent: `BSAS-offline-map/1.0 (border-safety-alert; educational field app)`
- Rate limiting: Configurable delay between requests (default 0.2s - 0.5s).
- Deduplication: Existing valid PNG tiles are skipped without re-requesting.
- Verification: Validates PNG magic bytes (`\x89PNG\r\n\x1a\n`) to prevent corrupted cache entries.

---

## 4. Mobile Device Deployment
Tiles can be provisioned onto physical Android test devices:
```powershell
adb push offline_tiles /sdcard/Download/bsas_offline_tiles
```
The app verifies `manifest.json` on startup and enables seamless rendering without cellular connectivity.
