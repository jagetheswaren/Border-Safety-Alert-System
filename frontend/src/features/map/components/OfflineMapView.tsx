"use client";

import React, { useEffect, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import {
  LatLngLiteral,
  BorderFeature,
  SafetyZoneFeature,
  IncidentMarkerItem,
  DeviceMarkerItem,
  MapLayersVisibility,
} from '../types/map.types';

interface OfflineMapViewProps {
  layers: MapLayersVisibility;
  borders: BorderFeature[];
  safetyZones: SafetyZoneFeature[];
  incidents: IncidentMarkerItem[];
  devices: DeviceMarkerItem[];
  userLocation: LatLngLiteral | null;
  selectedBorder: BorderFeature | null;
  onSelectBorder?: (border: BorderFeature) => void;
  centerTarget?: LatLngLiteral | null;
}

export function OfflineMapView({
  layers,
  borders,
  safetyZones,
  incidents,
  devices,
  userLocation,
  selectedBorder,
  onSelectBorder,
  centerTarget,
}: OfflineMapViewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<maplibregl.Marker[]>([]);
  const onSelectBorderRef = useRef(onSelectBorder);
  useEffect(() => {
    onSelectBorderRef.current = onSelectBorder;
  }, [onSelectBorder]);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    // Fast, lightweight, offline-compatible style with raster fallback
    const map = new maplibregl.Map({
      container: containerRef.current,
      style: {
        version: 8,
        sources: {
          'osm-tiles': {
            type: 'raster',
            tiles: [
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png'
            ],
            tileSize: 256,
            attribution: '&copy; Esri, TomTom, Garmin, FAO, NOAA, USGS | BSAS Map Engine',
          },
        },
        layers: [
          {
            id: 'osm-tiles-layer',
            type: 'raster',
            source: 'osm-tiles',
            minzoom: 0,
            maxzoom: 19,
          },
        ],
      },
      center: centerTarget ? [centerTarget.lng, centerTarget.lat] : [78.25, 10.35],
      zoom: 9,
    });

    mapRef.current = map;

    map.on('load', () => {
      // Add Border GeoJSON Source
      map.addSource('bsas-borders', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: borders as unknown as GeoJSON.Feature[],
        },
      });

      // Add Border Lines Layer
      map.addLayer({
        id: 'bsas-borders-line',
        type: 'line',
        source: 'bsas-borders',
        layout: {
          'line-join': 'round',
          'line-cap': 'round',
          visibility: layers.borders ? 'visible' : 'none',
        },
        paint: {
          'line-color': '#ef4444',
          'line-width': 4,
          'line-opacity': 0.9,
        },
      });

      // Add Safety Zones Source
      const zoneGeoJSONFeatures = safetyZones.map((z) => ({
        type: 'Feature' as const,
        id: z.id,
        properties: { name: z.name, color: z.color, severity: z.severity },
        geometry: {
          type: 'Polygon' as const,
          coordinates: [z.coordinates.map((pt) => [pt[1], pt[0]])],
        },
      }));

      map.addSource('bsas-zones', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: zoneGeoJSONFeatures as unknown as GeoJSON.Feature[],
        },
      });

      // Add Safety Zones Fill Layer
      map.addLayer({
        id: 'bsas-zones-fill',
        type: 'fill',
        source: 'bsas-zones',
        layout: {
          visibility: layers.safetyZones ? 'visible' : 'none',
        },
        paint: {
          'fill-color': ['get', 'color'],
          'fill-opacity': 0.25,
        },
      });

      map.addLayer({
        id: 'bsas-zones-outline',
        type: 'line',
        source: 'bsas-zones',
        layout: {
          visibility: layers.safetyZones ? 'visible' : 'none',
        },
        paint: {
          'line-color': ['get', 'color'],
          'line-width': 1.5,
        },
      });

      // Border line click listener
      map.on('click', 'bsas-borders-line', (e) => {
        if (e.features && e.features.length > 0 && onSelectBorderRef.current) {
          const feat = e.features[0];
          onSelectBorderRef.current({
            type: 'Feature',
            id: String(feat.id || feat.properties?.id || ''),
            properties: feat.properties as BorderFeature['properties'],
            geometry: feat.geometry as BorderFeature['geometry'],
          });
        }
      });
    });

    return () => {
      map.remove();
      mapRef.current = null;
    };
    // Initialize once on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Update borders data when changed
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !map.isStyleLoaded()) return;

    const src = map.getSource('bsas-borders') as maplibregl.GeoJSONSource;
    if (src) {
      src.setData({
        type: 'FeatureCollection',
        features: borders as unknown as GeoJSON.Feature[],
      });
    }
  }, [borders]);

  // Update layer visibility
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !map.isStyleLoaded()) return;

    if (map.getLayer('bsas-borders-line')) {
      map.setLayoutProperty('bsas-borders-line', 'visibility', layers.borders ? 'visible' : 'none');
    }
    if (map.getLayer('bsas-zones-fill')) {
      map.setLayoutProperty('bsas-zones-fill', 'visibility', layers.safetyZones ? 'visible' : 'none');
    }
    if (map.getLayer('bsas-zones-outline')) {
      map.setLayoutProperty('bsas-zones-outline', 'visibility', layers.safetyZones ? 'visible' : 'none');
    }
  }, [layers.borders, layers.safetyZones]);

  // Update markers (Incidents, Devices, User position)
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    // Clean up old markers
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];

    const newMarkers: maplibregl.Marker[] = [];

    // Incidents
    if (layers.incidents) {
      incidents.forEach((inc) => {
        if (!inc.latitude || !inc.longitude) return;

        const el = document.createElement('div');
        el.className = 'w-4 h-4 rounded-full bg-red-600 border-2 border-white shadow-md cursor-pointer';
        el.title = `${inc.title} (${inc.severity})`;

        const popup = new maplibregl.Popup({ offset: 15 }).setHTML(`
          <div style="font-family: sans-serif; font-size: 11px; padding: 2px;">
            <b>${inc.title}</b><br/>
            <span style="color: #ef4444; font-weight: bold;">${inc.severity}</span> - ${inc.status}
          </div>
        `);

        const marker = new maplibregl.Marker({ element: el })
          .setLngLat([inc.longitude, inc.latitude])
          .setPopup(popup)
          .addTo(map);

        newMarkers.push(marker);
      });
    }

    // Active Field Devices
    if (layers.devices) {
      devices.forEach((dev) => {
        if (!dev.latitude || !dev.longitude) return;

        const devEl = document.createElement('div');
        devEl.className = 'w-4 h-4 rounded-full bg-emerald-500 border-2 border-white shadow-md cursor-pointer';
        devEl.title = `Unit ${dev.deviceId} (${dev.status})`;

        const popup = new maplibregl.Popup({ offset: 15 }).setHTML(`
          <div style="font-family: sans-serif; font-size: 11px; padding: 2px;">
            <b>Unit: ${dev.deviceId}</b><br/>
            Status: <span style="color: #10b981; font-weight: bold;">${dev.status}</span>
          </div>
        `);

        const marker = new maplibregl.Marker({ element: devEl })
          .setLngLat([dev.longitude, dev.latitude])
          .setPopup(popup)
          .addTo(map);

        newMarkers.push(marker);
      });
    }

    // User Location
    if (userLocation) {
      const userEl = document.createElement('div');
      userEl.className = 'w-5 h-5 rounded-full bg-blue-500 border-2 border-white ring-4 ring-blue-500/25';
      userEl.title = 'Your GPS Location';

      const userMarker = new maplibregl.Marker({ element: userEl })
        .setLngLat([userLocation.lng, userLocation.lat])
        .addTo(map);

      newMarkers.push(userMarker);
    }

    markersRef.current = newMarkers;
  }, [incidents, devices, userLocation, layers.incidents, layers.devices]);

  return (
    <div className="w-full h-full relative">
      <div ref={containerRef} className="w-full h-full" />
      <div className="absolute top-4 right-6 z-10 px-3 py-1 bg-amber-950/90 border border-amber-800 text-amber-300 rounded-lg text-xs font-semibold shadow-lg backdrop-blur-sm">
        Offline MapLibre Mode Active {selectedBorder ? `| ${selectedBorder.properties.boundary_name}` : ''}
      </div>
    </div>
  );
}
