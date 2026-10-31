/** Decode backend Polygon GeoJSON or legacy WKT; preserve GeoJSON [longitude, latitude]. */
export function parseZoneGeometry(input: unknown): { type: 'Polygon'; coordinates: number[][][] } {
  let value: unknown = input;
  if (typeof input === 'string') {
    const wkt = input.trim().match(/^POLYGON\s*\(\((.*)\)\)$/i);
    value = wkt ? { type: 'Polygon', coordinates: wkt[1].split(/\)\s*,\s*\(/).map(ring => ring.split(',').map(point => point.trim().split(/\s+/).map(Number))) } : JSON.parse(input);
  }
  const polygon = value as { type?: string; coordinates?: number[][][] } | null;
  if (!polygon || polygon.type !== 'Polygon' || !Array.isArray(polygon.coordinates) || polygon.coordinates.length === 0) throw new Error('Unsupported or missing safety-zone polygon');
  for (const ring of polygon.coordinates) {
    if (!Array.isArray(ring) || ring.length < 4 || ring.some(p => !Array.isArray(p) || p.length < 2 || !Number.isFinite(p[0]) || !Number.isFinite(p[1]) || Math.abs(p[0]) > 180 || Math.abs(p[1]) > 90)) throw new Error('Invalid safety-zone coordinates');
    if (ring[0][0] !== ring[ring.length - 1][0] || ring[0][1] !== ring[ring.length - 1][1]) throw new Error('Safety-zone polygon is not closed');
  }
  return polygon as { type: 'Polygon'; coordinates: number[][][] };
}
