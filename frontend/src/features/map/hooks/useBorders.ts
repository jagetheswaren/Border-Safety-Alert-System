"use client";

import { parseZoneGeometry } from '../services/zoneGeometry';
import { fetchWithAuth, getZones } from '@/lib/api';
import { useState, useEffect, useCallback, useMemo } from 'react';
import { BorderFeatureCollection, BorderFeature, SafetyZoneFeature, SafetyZoneConfig, LatLngLiteral } from '../types/map.types';
import { evaluateNearestBorder, DEFAULT_SAFETY_CONFIG } from '../services/maps.service';

export function useBorders(userLocation: LatLngLiteral | null = null) {
  const [bordersCollection, setBordersCollection] = useState<BorderFeatureCollection | null>(null);
  const [safetyZones, setSafetyZones] = useState<SafetyZoneFeature[]>([]);
  const [metadata, setMetadata] = useState<Record<string, unknown> | null>(null);
  const [selectedBorder, setSelectedBorder] = useState<BorderFeature | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBordersData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const bordersData = await (await fetchWithAuth('/borders/')).json() as BorderFeatureCollection;
      const zones = await getZones();
      const zonesFeatures: SafetyZoneFeature[] = zones.filter(z => z.enabled !== false).map(z => {
        const geometry = parseZoneGeometry(z.geometry);
        if (geometry.type !== 'Polygon' || !Array.isArray(geometry.coordinates?.[0])) throw new Error(`Invalid polygon for zone ${z.name}`);
        return { id: String(z.id), name: z.name, zone_type: 'WARNING', severity: z.severity, color: '#f59e0b', fillOpacity: 0.25, warning_radius_m: z.warning_radius_m ?? 0, rings: geometry.coordinates.map(ring => ring.map(pt => [pt[1], pt[0]] as [number, number])), coordinates: geometry.coordinates[0].map((pt: number[]) => [pt[1], pt[0]] as [number, number]) };
      });

      // 3. Fetch metadata
      try {
        const metaRes = await fetch('/data/borders/metadata.json');
        if (metaRes.ok) {
          setMetadata(await metaRes.json());
        }
      } catch {
        // Ignored
      }

      if (bordersData && bordersData.features) {
        setBordersCollection(bordersData);
        setSafetyZones(zonesFeatures);
      } else {
        throw new Error('Border dataset could not be loaded.');
      }
    } catch (err: unknown) {
      console.error('Failed to load borders data:', err);
      setError(err instanceof Error ? err.message : 'Error loading border dataset');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const init = async () => {
      await Promise.resolve();
      await fetchBordersData();
    };
    init();
  }, [fetchBordersData]);

  // Evaluate closest boundary and current safety risk state
  const proximity = useMemo(() => {
    const config: SafetyZoneConfig =
      (metadata?.safety_zones_config as SafetyZoneConfig) || DEFAULT_SAFETY_CONFIG;
    return evaluateNearestBorder(userLocation, bordersCollection, config);
  }, [userLocation, bordersCollection, metadata]);

  return {
    borders: bordersCollection?.features || [],
    bordersCollection,
    safetyZones,
    metadata,
    selectedBorder,
    setSelectedBorder,
    nearestBorderEvaluation: proximity,
    isLoading,
    error,
    refreshBorders: fetchBordersData,
  };
}
