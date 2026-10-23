import * as turf from '@turf/turf';
import { LatLngLiteral, SafetyZoneConfig, BorderFeature, BorderFeatureCollection } from '../types/map.types';

export const DEFAULT_SAFETY_CONFIG: SafetyZoneConfig = {
  awarenessMeters: 2000,
  warningMeters: 1000,
  criticalMeters: 300,
};

/**
 * Calculates geodesic distance in meters between a user position and a GeoJSON feature (LineString or Polygon).
 */
export function calculateDistanceToFeature(
  userPos: LatLngLiteral,
  feature: BorderFeature
): { distanceMeters: number; nearestPoint: LatLngLiteral; isInside: boolean } {
  try {
    const pt = turf.point([userPos.lng, userPos.lat]);
    const geomType = feature.geometry.type;

    if (geomType === 'Polygon' || geomType === 'MultiPolygon') {
      const isInside = turf.booleanPointInPolygon(
        pt,
        feature.geometry as unknown as Parameters<typeof turf.booleanPointInPolygon>[1]
      );
      if (isInside) {
        return { distanceMeters: 0, nearestPoint: userPos, isInside: true };
      }
      const lineGeom = turf.polygonToLine(
        feature.geometry as unknown as Parameters<typeof turf.polygonToLine>[0]
      );
      const nearest = turf.nearestPointOnLine(
        lineGeom as unknown as Parameters<typeof turf.nearestPointOnLine>[0],
        pt
      );
      const distKm = turf.distance(pt, nearest, { units: 'kilometers' });
      return {
        distanceMeters: Math.round(distKm * 1000),
        nearestPoint: { lat: nearest.geometry.coordinates[1], lng: nearest.geometry.coordinates[0] },
        isInside: false,
      };
    } else if (geomType === 'LineString' || geomType === 'MultiLineString') {
      const nearest = turf.nearestPointOnLine(
        feature.geometry as unknown as Parameters<typeof turf.nearestPointOnLine>[0],
        pt
      );
      const distKm = turf.distance(pt, nearest, { units: 'kilometers' });
      return {
        distanceMeters: Math.round(distKm * 1000),
        nearestPoint: { lat: nearest.geometry.coordinates[1], lng: nearest.geometry.coordinates[0] },
        isInside: false,
      };
    }
  } catch (err) {
    console.error('Error calculating geodesic distance:', err);
  }

  // Fallback direct distance calculation
  return { distanceMeters: Infinity, nearestPoint: userPos, isInside: false };
}

/**
 * Finds the closest border feature and evaluates safety risk status.
 */
export function evaluateNearestBorder(
  userPos: LatLngLiteral | null,
  collection: BorderFeatureCollection | null,
  config: SafetyZoneConfig = DEFAULT_SAFETY_CONFIG
): {
  nearestBorder: BorderFeature | null;
  distanceMeters: number;
  safetyState: 'SAFE' | 'AWARENESS' | 'WARNING' | 'CRITICAL' | 'UNKNOWN';
} {
  if (!userPos || !collection || !collection.features || collection.features.length === 0) {
    return { nearestBorder: null, distanceMeters: Infinity, safetyState: 'UNKNOWN' };
  }

  let minDistance = Infinity;
  let closestFeature: BorderFeature | null = null;
  let insideExclusion = false;

  for (const feature of collection.features) {
    const { distanceMeters, isInside } = calculateDistanceToFeature(userPos, feature);
    if (isInside) {
      insideExclusion = true;
      closestFeature = feature;
      minDistance = 0;
      break;
    }
    if (distanceMeters < minDistance) {
      minDistance = distanceMeters;
      closestFeature = feature;
    }
  }

  let safetyState: 'SAFE' | 'AWARENESS' | 'WARNING' | 'CRITICAL' = 'SAFE';
  if (insideExclusion || minDistance <= config.criticalMeters) {
    safetyState = 'CRITICAL';
  } else if (minDistance <= config.warningMeters) {
    safetyState = 'WARNING';
  } else if (minDistance <= config.awarenessMeters) {
    safetyState = 'AWARENESS';
  }

  return { nearestBorder: closestFeature, distanceMeters: minDistance, safetyState };
}
