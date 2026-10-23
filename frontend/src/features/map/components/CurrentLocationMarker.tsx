"use client";

import { useEffect, useRef } from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import { LatLngLiteral } from '../types/map.types';

interface CurrentLocationMarkerProps {
  coords: LatLngLiteral | null;
  accuracy: number | null;
}

export function CurrentLocationMarker({ coords, accuracy }: CurrentLocationMarkerProps) {
  const map = useMap();
  const markerRef = useRef<google.maps.Marker | null>(null);
  const circleRef = useRef<google.maps.Circle | null>(null);

  useEffect(() => {
    if (markerRef.current) markerRef.current.setMap(null);
    if (circleRef.current) circleRef.current.setMap(null);

    if (!map || !coords || !window.google?.maps) return;

    // Glowing blue user dot
    const dotIcon = {
      path: google.maps.SymbolPath.CIRCLE,
      fillColor: '#2563eb',
      fillOpacity: 1.0,
      strokeColor: '#ffffff',
      strokeWeight: 2.5,
      scale: 8,
    };

    markerRef.current = new google.maps.Marker({
      position: coords,
      map,
      icon: dotIcon,
      zIndex: 999,
      title: 'Your Current GPS Position',
    });

    if (accuracy && accuracy > 0) {
      circleRef.current = new google.maps.Circle({
        center: coords,
        radius: Math.min(accuracy, 2000), // Cap visual radius at 2km
        strokeColor: '#3b82f6',
        strokeOpacity: 0.5,
        strokeWeight: 1,
        fillColor: '#3b82f6',
        fillOpacity: 0.12,
        map,
        clickable: false,
      });
    }

    return () => {
      if (markerRef.current) markerRef.current.setMap(null);
      if (circleRef.current) circleRef.current.setMap(null);
    };
  }, [map, coords, accuracy]);

  return null;
}
