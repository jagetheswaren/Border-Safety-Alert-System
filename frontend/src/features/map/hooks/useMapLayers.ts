"use client";

import { useState } from 'react';
import { MapLayersVisibility, MapTypeMode } from '../types/map.types';

const STORAGE_LAYERS_KEY = 'bsas_map_layers_pref';
const STORAGE_MAP_TYPE_KEY = 'bsas_map_type_pref';

const DEFAULT_LAYERS: MapLayersVisibility = {
  borders: true,
  safetyZones: true,
  incidents: true,
  devices: true,
  traffic: false,
  route: true,
  legend: true,
};

export function useMapLayers() {
  const [layers, setLayers] = useState<MapLayersVisibility>(() => {
    if (typeof window === 'undefined') return DEFAULT_LAYERS;
    try {
      const saved = localStorage.getItem(STORAGE_LAYERS_KEY);
      return saved ? { ...DEFAULT_LAYERS, ...JSON.parse(saved) } : DEFAULT_LAYERS;
    } catch {
      return DEFAULT_LAYERS;
    }
  });

  const [mapType, setMapType] = useState<MapTypeMode>(() => {
    if (typeof window === 'undefined') return 'roadmap';
    try {
      const saved = localStorage.getItem(STORAGE_MAP_TYPE_KEY) as MapTypeMode;
      return saved && ['roadmap', 'satellite', 'hybrid', 'terrain'].includes(saved)
        ? saved
        : 'roadmap';
    } catch {
      return 'roadmap';
    }
  });

  const toggleLayer = (layerKey: keyof MapLayersVisibility) => {
    setLayers((prev) => {
      const next = { ...prev, [layerKey]: !prev[layerKey] };
      try {
        localStorage.setItem(STORAGE_LAYERS_KEY, JSON.stringify(next));
      } catch {
        // Ignore storage write error
      }
      return next;
    });
  };

  const changeMapType = (type: MapTypeMode) => {
    setMapType(type);
    try {
      localStorage.setItem(STORAGE_MAP_TYPE_KEY, type);
    } catch {
      // Ignore storage write error
    }
  };

  return {
    layers,
    mapType,
    toggleLayer,
    setMapType: changeMapType,
  };
}
