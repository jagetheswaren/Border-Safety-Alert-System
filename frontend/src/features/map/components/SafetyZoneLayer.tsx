"use client";

import { useEffect, useRef } from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import { SafetyZoneFeature } from '../types/map.types';

interface SafetyZoneLayerProps {
  zones: SafetyZoneFeature[];
  visible: boolean;
  onSelectZone?: (zone: SafetyZoneFeature) => void;
}

export function SafetyZoneLayer({ zones, visible, onSelectZone }: SafetyZoneLayerProps) {
  const map = useMap();
  const polygonsRef = useRef<google.maps.Polygon[]>([]);

  useEffect(() => {
    // Clean up existing polygons
    polygonsRef.current.forEach((poly) => poly.setMap(null));
    polygonsRef.current = [];

    if (!map || !visible || zones.length === 0 || !window.google?.maps) {
      return;
    }

    const createdPolygons: google.maps.Polygon[] = [];

    zones.forEach((zone) => {
      const paths = zone.coordinates.map((pt) => ({ lat: pt[0], lng: pt[1] }));
      if (paths.length < 3) return;

      const color = zone.color || '#3b82f6';

      const polygon = new google.maps.Polygon({
        paths,
        strokeColor: color,
        strokeOpacity: 0.8,
        strokeWeight: 1.5,
        fillColor: color,
        fillOpacity: zone.fillOpacity || 0.25,
        map,
        clickable: true,
      });

      polygon.addListener('mouseover', () => {
        polygon.setOptions({ fillOpacity: (zone.fillOpacity || 0.25) + 0.15, strokeWeight: 2.5 });
      });

      polygon.addListener('mouseout', () => {
        polygon.setOptions({ fillOpacity: zone.fillOpacity || 0.25, strokeWeight: 1.5 });
      });

      if (onSelectZone) {
        polygon.addListener('click', () => {
          onSelectZone(zone);
        });
      }

      createdPolygons.push(polygon);
    });

    polygonsRef.current = createdPolygons;

    return () => {
      createdPolygons.forEach((poly) => poly.setMap(null));
    };
  }, [map, zones, visible, onSelectZone]);

  return null;
}
