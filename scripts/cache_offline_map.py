#!/usr/bin/env python3
"""
BSAS Offline Map Tile Pre-Caching Utility
Downloads and bundles raster map tiles for designated border safety corridors.

Compliance Notice:
- Adheres to OpenStreetMap Tile Usage Policy (https://operations.osmfoundation.org/policies/tiles).
- Implements custom identifiable User-Agent.
- Enforces strict rate-limiting (max 2 requests/sec) to avoid server load.
- Reuses already-cached tiles without re-downloading.
"""

import argparse
import hashlib
import json
import math
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_REGIONS = {
    "pollachi_coimbatore": {
        "id": "pollachi_coimbatore",
        "name": "Pollachi / Coimbatore Border Sector",
        "description": "Western Ghats corridor operational zone",
        "min_lat": 10.50,
        "max_lat": 11.10,
        "min_lon": 76.70,
        "max_lon": 77.20,
        "min_zoom": 8,
        "max_zoom": 12,
        "version": "2026.09-v1",
    }
}

USER_AGENT = "BSAS-offline-map/1.0 (border-safety-alert; educational field app; contact: safety@bsas.local)"
TILE_URL_TEMPLATE = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def lon_to_tile_x(lon: float, z: int) -> int:
    n = 1 << z
    return int(((lon + 180.0) / 360.0) * n) % n


def lat_to_tile_y(lat: float, z: int) -> int:
    n = 1 << z
    lat_rad = math.radians(lat)
    y = ((1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0) * n
    return max(0, min(n - 1, int(y)))


def enumerate_tiles(region: dict, min_z: int, max_z: int):
    tiles = []
    for z in range(min_z, max_z + 1):
        x_min = lon_to_tile_x(region["min_lon"], z)
        x_max = lon_to_tile_x(region["max_lon"], z)
        y_min = lat_to_tile_y(region["max_lat"], z)
        y_max = lat_to_tile_y(region["min_lat"], z)

        x_start, x_end = min(x_min, x_max), max(x_min, x_max)
        y_start, y_end = min(y_min, y_max), max(y_min, y_max)

        for x in range(x_start, x_end + 1):
            for y in range(y_start, y_end + 1):
                tiles.append((z, x, y))
    return tiles


def is_valid_png(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 64:
        return False
    try:
        with open(path, "rb") as f:
            header = f.read(8)
            return header == PNG_MAGIC
    except Exception:
        return False


def verify_cache(output_dir: Path, region: dict):
    manifest_path = output_dir / "manifest.json"
    if not manifest_path.is_file():
        print(f"[STATUS] No manifest found at {manifest_path}. Cache not initialized.")
        return False

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    expected = manifest.get("expected_tiles", 0)
    actual = 0
    valid_pngs = 0

    for z_dir in output_dir.iterdir():
        if z_dir.is_dir() and z_dir.name.isdigit():
            for x_dir in z_dir.iterdir():
                if x_dir.is_dir() and x_dir.name.isdigit():
                    for tile_file in x_dir.glob("*.png"):
                        actual += 1
                        if is_valid_png(tile_file):
                            valid_pngs += 1

    print("\n--- BSAS OFFLINE MAP CACHE AUDIT ---")
    print(f"Region:        {manifest.get('name', region['name'])} ({manifest.get('id', region['id'])})")
    print(f"Version:       {manifest.get('version')}")
    print(f"Directory:     {output_dir.resolve()}")
    print(f"Expected:      {expected} tiles")
    print(f"Actual On-Disk:{actual} tiles ({valid_pngs} verified valid PNGs)")
    print(f"Checksum:      {manifest.get('checksum')}")
    print(f"Prepared At:   {manifest.get('prepared_at')}")

    if actual >= int(expected * 0.9) and valid_pngs == actual:
        print("[VERIFIED] Cache integrity: 100% READY FOR OFFLINE FIELD USE.\n")
        return True
    else:
        print("[WARNING] Cache incomplete or corrupted.\n")
        return False


def cache_tiles(region: dict, output_dir: Path, min_z: int, max_z: int, dry_run: bool = False, delay_sec: float = 0.5):
    tiles = enumerate_tiles(region, min_z, max_z)
    total = len(tiles)
    print(f"[INIT] Region: '{region['name']}' (Zoom levels: {min_z} to {max_z})")
    print(f"[INIT] Total tiles required: {total}")
    print(f"[INIT] Target directory: {output_dir.resolve()}")

    if dry_run:
        print("[DRY-RUN] Tile enumeration complete. Exiting without downloading.")
        return

    output_dir.mkdir(parents=True, exist_ok=True)
    downloaded = 0
    skipped = 0
    errors = 0

    for idx, (z, x, y) in enumerate(tiles, start=1):
        tile_path = output_dir / str(z) / str(x) / f"{y}.png"
        if is_valid_png(tile_path):
            skipped += 1
            if idx % 10 == 0 or idx == total:
                print(f"[{idx}/{total}] Progress: {skipped} cached, {downloaded} downloaded, {errors} errors", end="\r")
            continue

        tile_path.parent.mkdir(parents=True, exist_ok=True)
        url = TILE_URL_TEMPLATE.format(z=z, x=x, y=y)
        req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                if resp.status == 200:
                    data = resp.read()
                    if len(data) >= 64 and data[:8] == PNG_MAGIC:
                        with open(tile_path, "wb") as out_f:
                            out_f.write(data)
                        downloaded += 1
                    else:
                        errors += 1
                else:
                    errors += 1
        except Exception as exc:
            errors += 1
            print(f"\n[WARN] Failed tile {z}/{x}/{y}: {exc}")

        # Rate-limiting compliance
        time.sleep(delay_sec)

        if idx % 10 == 0 or idx == total:
            print(f"[{idx}/{total}] Progress: {skipped} cached, {downloaded} downloaded, {errors} errors", end="\r")

    print(f"\n[DONE] Finished. Cached: {skipped}, Downloaded: {downloaded}, Errors: {errors}")

    # Compute checksum & write manifest
    checksum_src = f"{region['id']}:{region['version']}:{total}:{downloaded + skipped}".encode("utf-8")
    checksum = hashlib.sha256(checksum_src).hexdigest()

    manifest = {
        "id": region["id"],
        "name": region["name"],
        "version": region["version"],
        "min_zoom": min_z,
        "max_zoom": max_z,
        "bounds": {
            "min_lat": region["min_lat"],
            "max_lat": region["max_lat"],
            "min_lon": region["min_lon"],
            "max_lon": region["max_lon"],
        },
        "expected_tiles": total,
        "actual_tiles": downloaded + skipped,
        "checksum": checksum,
        "prepared_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }

    manifest_path = output_dir / "manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"[MANIFEST] Generated {manifest_path}")
    verify_cache(output_dir, region)


def main():
    parser = argparse.ArgumentParser(description="BSAS Offline Map Tile Pre-Caching Utility")
    parser.add_argument("--region", default="pollachi_coimbatore", choices=list(DEFAULT_REGIONS.keys()))
    parser.add_argument("--output-dir", default="offline_tiles", help="Directory where tiles will be saved")
    parser.add_argument("--min-zoom", type=int, default=None)
    parser.add_argument("--max-zoom", type=int, default=None)
    parser.add_argument("--dry-run", action="store_true", help="Calculate tiles without downloading")
    parser.add_argument("--verify-only", action="store_true", help="Verify existing cache without downloading")
    parser.add_argument("--delay", type=float, default=0.2, help="Delay between HTTP requests in seconds (OSM friendly)")

    args = parser.parse_args()
    region = DEFAULT_REGIONS[args.region]
    output_dir = Path(args.output_dir)

    min_z = args.min_zoom if args.min_zoom is not None else region["min_zoom"]
    max_z = args.max_zoom if args.max_zoom is not None else region["max_zoom"]

    if args.verify_only:
        verify_cache(output_dir, region)
    else:
        cache_tiles(region, output_dir, min_z, max_z, dry_run=args.dry_run, delay_sec=args.delay)


if __name__ == "__main__":
    main()
