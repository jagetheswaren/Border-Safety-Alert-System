"use client";

import { useState, useEffect, useCallback, useMemo } from 'react';
import { BorderFeatureCollection, BorderFeature, SafetyZoneFeature, SafetyZoneConfig, LatLngLiteral } from '../types/map.types';
import { evaluateNearestBorder, DEFAULT_SAFETY_CONFIG } from '../services/maps.service';

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');

interface RawZoneFeature {
  id?: string;
  properties?: {
    id?: string;
    name?: string;
    zone_type?: string;
    severity?: string;
    safety_level?: string;
    color?: string;
    fillOpacity?: number;
    warning_radius_m?: number;
    description?: string;
  };
  geometry?: {
    coordinates?: number[][][];
  };
}

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
      const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;

      // 1. Fetch borders from backend or local static fallback
      let bordersData: BorderFeatureCollection | null = null;
      try {
        const res = await fetch(`${API_BASE}/borders/`, { headers, cache: 'no-store' });
        if (res.ok) {
          bordersData = await res.json();
        }
      } catch (e) {
        console.warn('Backend borders endpoint not reachable, attempting static file...', e);
      }

      if (!bordersData) {
        const staticRes = await fetch('/data/borders/borders.geojson');
        if (staticRes.ok) {
          bordersData = await staticRes.json();
        }
      }

      // 2. Fetch zones
      let zonesFeatures: SafetyZoneFeature[] = [];
      try {
        const zonesRes = await fetch('/data/borders/zones.geojson');
        if (zonesRes.ok) {
          const zonesJson = await zonesRes.json();
          zonesFeatures = ((zonesJson.features as RawZoneFeature[]) || []).map((f) => ({
            id: f.id || f.properties?.id || 'zone',
            name: f.properties?.name || 'Safety Zone',
            zone_type: (f.properties?.zone_type as SafetyZoneFeature['zone_type']) || 'WARNING',
            severity: (f.properties?.severity as SafetyZoneFeature['severity']) || 'HIGH',
            safety_level: f.properties?.safety_level,
            color: f.properties?.color || '#f59e0b',
            fillOpacity: f.properties?.fillOpacity || 0.25,
            warning_radius_m: f.properties?.warning_radius_m || 500,
            description: f.properties?.description,
            coordinates: (f.geometry?.coordinates?.[0] || []).map((pt: number[]) => [pt[1], pt[0]]),
          }));
        }
      } catch (e) {
        console.warn('Zones dataset load error', e);
      }

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
