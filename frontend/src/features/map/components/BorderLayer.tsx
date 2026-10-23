"use client";

import { useEffect, useRef } from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import { BorderFeature } from '../types/map.types';

interface BorderLayerProps {
  borders: BorderFeature[];
  visible: boolean;
  selectedBorderId?: string | null;
  onSelectBorder?: (border: BorderFeature) => void;
}

export function BorderLayer({
  borders,
  visible,
  selectedBorderId,
  onSelectBorder,
}: BorderLayerProps) {
  const map = useMap();
  const polylinesRef = useRef<google.maps.Polyline[]>([]);

  useEffect(() => {
    // Clean up existing polylines
    polylinesRef.current.forEach((pl) => pl.setMap(null));
    polylinesRef.current = [];

    if (!map || !visible || borders.length === 0 || !window.google?.maps) {
      return;
    }

    const createdLines: google.maps.Polyline[] = [];

    borders.forEach((feature) => {
      const geom = feature.geometry;
      const props = feature.properties;
      const isSelected = selectedBorderId === props.id;

      // Extract coordinates into google.maps.LatLngLiteral[]
      let paths: google.maps.LatLngLiteral[] = [];

      if (geom.type === 'LineString') {
        paths = (geom.coordinates as number[][]).map((coord) => ({
          lat: coord[1],
          lng: coord[0],
        }));
      } else if (geom.type === 'MultiLineString') {
        const rings = geom.coordinates as number[][][];
        paths = rings.flat().map((coord) => ({
          lat: coord[1],
          lng: coord[0],
        }));
      } else if (geom.type === 'Polygon') {
        // Outline of the polygon
        const ring = (geom.coordinates as number[][][])[0] || [];
        paths = ring.map((coord) => ({
          lat: coord[1],
          lng: coord[0],
        }));
      }

      if (paths.length < 2) return;

      const baseColor =
        props.risk_level === 'CRITICAL'
          ? '#ef4444'
          : props.risk_level === 'WARNING'
          ? '#f59e0b'
          : '#3b82f6';

      const polyline = new google.maps.Polyline({
        path: paths,
        geodesic: true,
        strokeColor: isSelected ? '#ffffff' : baseColor,
        strokeOpacity: isSelected ? 1.0 : 0.9,
        strokeWeight: isSelected ? 5 : 3.5,
        clickable: true,
        map,
      });

      // Hover and click listeners
      polyline.addListener('mouseover', () => {
        polyline.setOptions({ strokeWeight: 6, strokeOpacity: 1.0 });
      });

      polyline.addListener('mouseout', () => {
        polyline.setOptions({
          strokeWeight: isSelected ? 5 : 3.5,
          strokeOpacity: isSelected ? 1.0 : 0.9,
        });
      });

      polyline.addListener('click', () => {
        if (onSelectBorder) {
          onSelectBorder(feature);
        }
      });

      createdLines.push(polyline);
    });

    polylinesRef.current = createdLines;

    return () => {
      createdLines.forEach((pl) => pl.setMap(null));
    };
  }, [map, borders, visible, selectedBorderId, onSelectBorder]);

  return null;
}
