"use client";

import { useEffect, useRef } from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import { DeviceMarkerItem } from '../types/map.types';

interface DeviceLayerProps {
  devices: DeviceMarkerItem[];
  visible: boolean;
}

export function DeviceLayer({ devices, visible }: DeviceLayerProps) {
  const map = useMap();
  const markersRef = useRef<google.maps.Marker[]>([]);
  const infoWindowRef = useRef<google.maps.InfoWindow | null>(null);

  useEffect(() => {
    markersRef.current.forEach((m) => m.setMap(null));
    markersRef.current = [];

    if (!map || !visible || devices.length === 0 || !window.google?.maps) {
      return;
    }

    infoWindowRef.current = new google.maps.InfoWindow({ maxWidth: 260 });
    const created: google.maps.Marker[] = [];

    devices.forEach((dev) => {
      const pinIcon = {
        path: google.maps.SymbolPath.CIRCLE,
        fillColor: '#10b981',
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 2,
        scale: 7,
      };

      const marker = new google.maps.Marker({
        position: { lat: dev.latitude, lng: dev.longitude },
        map,
        icon: pinIcon,
        title: `Field Device: ${dev.deviceId}`,
      });

      marker.addListener('click', () => {
        const content = `
          <div style="font-family: ui-sans-serif, system-ui, sans-serif; padding: 4px; color: #111827;">
            <div style="font-size: 11px; font-weight: 700; color: #047857; margin-bottom: 2px;">ACTIVE FIELD UNIT</div>
            <div style="font-size: 12px; font-weight: 600;">ID: ${dev.deviceId}</div>
            <div style="font-size: 10px; color: #6b7280; margin-top: 4px;">
              Lat: ${dev.latitude.toFixed(5)}<br/>
              Lng: ${dev.longitude.toFixed(5)}<br/>
              Speed: ${dev.speed ? `${dev.speed.toFixed(1)} m/s` : 'Stationary'}<br/>
              Last Fix: ${new Date(dev.timestamp).toLocaleTimeString()}
            </div>
          </div>
        `;
        if (infoWindowRef.current) {
          infoWindowRef.current.setContent(content);
          infoWindowRef.current.open(map, marker);
        }
      });

      created.push(marker);
    });

    markersRef.current = created;

    return () => {
      created.forEach((m) => m.setMap(null));
      if (infoWindowRef.current) infoWindowRef.current.close();
    };
  }, [map, devices, visible]);

  return null;
}
