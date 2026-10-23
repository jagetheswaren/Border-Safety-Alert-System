"use client";

import { useEffect, useRef } from 'react';
import { useMap } from '@vis.gl/react-google-maps';
import { MarkerClusterer } from '@googlemaps/markerclusterer';
import { IncidentMarkerItem } from '../types/map.types';

interface IncidentLayerProps {
  incidents: IncidentMarkerItem[];
  visible: boolean;
  onSelectIncident?: (incident: IncidentMarkerItem) => void;
}

export function IncidentLayer({ incidents, visible, onSelectIncident }: IncidentLayerProps) {
  const map = useMap();
  const clustererRef = useRef<MarkerClusterer | null>(null);
  const infoWindowRef = useRef<google.maps.InfoWindow | null>(null);

  useEffect(() => {
    if (clustererRef.current) {
      clustererRef.current.clearMarkers();
      clustererRef.current = null;
    }
    if (infoWindowRef.current) {
      infoWindowRef.current.close();
    }

    if (!map || !visible || incidents.length === 0 || !window.google?.maps) {
      return;
    }

    infoWindowRef.current = new google.maps.InfoWindow({
      maxWidth: 320,
    });

    const markers: google.maps.Marker[] = [];

    incidents.forEach((inc) => {
      if (!inc.latitude || !inc.longitude) return;

      const markerColor =
        inc.severity === 'CRITICAL'
          ? '#ef4444'
          : inc.severity === 'HIGH'
          ? '#f59e0b'
          : '#3b82f6';

      // SVG Pin for high-DPI crisp rendering
      const pinSvg = {
        path: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z',
        fillColor: markerColor,
        fillOpacity: 1.0,
        strokeColor: '#ffffff',
        strokeWeight: 1.5,
        scale: 1.5,
        anchor: new google.maps.Point(12, 22),
      };

      const marker = new google.maps.Marker({
        position: { lat: inc.latitude, lng: inc.longitude },
        title: inc.title,
        icon: pinSvg,
      });

      marker.addListener('click', () => {
        const content = `
          <div style="font-family: ui-sans-serif, system-ui, sans-serif; padding: 4px; color: #111827; max-width: 260px;">
            <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px;">
              <span style="font-size: 10px; font-weight: 700; color: #4b5563; text-transform: uppercase;">${inc.incidentNumber || 'INCIDENT'}</span>
              <span style="font-size: 10px; font-weight: 600; padding: 2px 6px; border-radius: 4px; background: ${
                inc.severity === 'CRITICAL' ? '#fee2e2' : '#fef3c7'
              }; color: ${inc.severity === 'CRITICAL' ? '#991b1b' : '#92400e'};">${inc.severity}</span>
            </div>
            <div style="font-size: 13px; font-weight: 700; line-height: 1.3; color: #111827;">${inc.title}</div>
            <p style="font-size: 11px; color: #4b5563; margin: 4px 0 8px 0; line-height: 1.4;">${inc.description || 'No description provided.'}</p>
            <div style="font-size: 10px; color: #6b7280; border-top: 1px solid #e5e7eb; padding-top: 4px; display: flex; justify-content: space-between;">
              <span>Status: <b>${inc.status}</b></span>
              <span>${new Date(inc.createdAt).toLocaleDateString()}</span>
            </div>
          </div>
        `;

        if (infoWindowRef.current) {
          infoWindowRef.current.setContent(content);
          infoWindowRef.current.open(map, marker);
        }

        if (onSelectIncident) {
          onSelectIncident(inc);
        }
      });

      markers.push(marker);
    });

    clustererRef.current = new MarkerClusterer({
      map,
      markers,
    });

    return () => {
      if (clustererRef.current) {
        clustererRef.current.clearMarkers();
      }
      if (infoWindowRef.current) {
        infoWindowRef.current.close();
      }
    };
  }, [map, incidents, visible, onSelectIncident]);

  return null;
}
