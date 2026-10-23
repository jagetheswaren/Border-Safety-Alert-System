"use client";

import React, { useEffect, useRef } from 'react';
import { APIProvider, Map, useMap } from '@vis.gl/react-google-maps';
import {
  LatLngLiteral,
  MapTypeMode,
  MapLayersVisibility,
  BorderFeature,
  SafetyZoneFeature,
  IncidentMarkerItem,
  DeviceMarkerItem,
  RouteInfo,
  PlaceResult,
} from '../types/map.types';
import { BorderLayer } from './BorderLayer';
import { SafetyZoneLayer } from './SafetyZoneLayer';
import { IncidentLayer } from './IncidentLayer';
import { DeviceLayer } from './DeviceLayer';
import { CurrentLocationMarker } from './CurrentLocationMarker';

interface GoogleMapViewProps {
  apiKey: string;
  mapId?: string;
  mapType: MapTypeMode;
  layers: MapLayersVisibility;
  borders: BorderFeature[];
  safetyZones: SafetyZoneFeature[];
  incidents: IncidentMarkerItem[];
  devices: DeviceMarkerItem[];
  userLocation: LatLngLiteral | null;
  userAccuracy: number | null;
  selectedBorder: BorderFeature | null;
  onSelectBorder: (border: BorderFeature) => void;
  onSelectIncident?: (incident: IncidentMarkerItem) => void;
  routeInfo: RouteInfo | null;
  selectedPlace: PlaceResult | null;
  onMapClick?: (latLng: LatLngLiteral) => void;
  centerTarget?: LatLngLiteral | null;
}

// Controller for internal map actions (camera fly-to, traffic layer, route polyline)
function MapInternalController({
  mapType,
  showTraffic,
  routeInfo,
  selectedPlace,
  centerTarget,
  onMapClick,
}: {
  mapType: MapTypeMode;
  showTraffic: boolean;
  routeInfo: RouteInfo | null;
  selectedPlace: PlaceResult | null;
  centerTarget?: LatLngLiteral | null;
  onMapClick?: (latLng: LatLngLiteral) => void;
}) {
  const map = useMap();
  const trafficLayerRef = useRef<google.maps.TrafficLayer | null>(null);
  const routePolylineRef = useRef<google.maps.Polyline | null>(null);
  const placeMarkerRef = useRef<google.maps.Marker | null>(null);

  // Sync MapType mode
  useEffect(() => {
    if (!map) return;
    map.setMapTypeId(mapType);
  }, [map, mapType]);

  // Traffic layer toggle
  useEffect(() => {
    if (!map || !window.google?.maps) return;

    if (showTraffic) {
      if (!trafficLayerRef.current) {
        trafficLayerRef.current = new google.maps.TrafficLayer();
      }
      trafficLayerRef.current.setMap(map);
    } else {
      if (trafficLayerRef.current) {
        trafficLayerRef.current.setMap(null);
      }
    }

    return () => {
      if (trafficLayerRef.current) {
        trafficLayerRef.current.setMap(null);
      }
    };
  }, [map, showTraffic]);

  // Route Polyline rendering
  useEffect(() => {
    if (routePolylineRef.current) {
      routePolylineRef.current.setMap(null);
      routePolylineRef.current = null;
    }

    if (!map || !routeInfo || routeInfo.polylinePath.length === 0 || !window.google?.maps) {
      return;
    }

    routePolylineRef.current = new google.maps.Polyline({
      path: routeInfo.polylinePath,
      geodesic: true,
      strokeColor: '#6366f1',
      strokeOpacity: 0.9,
      strokeWeight: 5,
      map,
    });

    // Fit map bounds to show complete route
    const bounds = new google.maps.LatLngBounds();
    routeInfo.polylinePath.forEach((pt) => bounds.extend(pt));
    map.fitBounds(bounds, 50);

    return () => {
      if (routePolylineRef.current) {
        routePolylineRef.current.setMap(null);
      }
    };
  }, [map, routeInfo]);

  // Selected Place marker
  useEffect(() => {
    if (placeMarkerRef.current) {
      placeMarkerRef.current.setMap(null);
      placeMarkerRef.current = null;
    }

    if (!map || !selectedPlace || !window.google?.maps) return;

    placeMarkerRef.current = new google.maps.Marker({
      position: selectedPlace.location,
      map,
      title: selectedPlace.name,
      animation: google.maps.Animation.DROP,
    });

    map.panTo(selectedPlace.location);
    map.setZoom(14);

    return () => {
      if (placeMarkerRef.current) {
        placeMarkerRef.current.setMap(null);
      }
    };
  }, [map, selectedPlace]);

  // Pan to centerTarget when updated
  useEffect(() => {
    if (!map || !centerTarget) return;
    map.panTo(centerTarget);
  }, [map, centerTarget]);

  // Click on map listener
  useEffect(() => {
    if (!map || !onMapClick) return;

    const listener = map.addListener('click', (e: google.maps.MapMouseEvent) => {
      if (e.latLng) {
        onMapClick({ lat: e.latLng.lat(), lng: e.latLng.lng() });
      }
    });

    return () => {
      google.maps.event.removeListener(listener);
    };
  }, [map, onMapClick]);

  return null;
}

export function GoogleMapView({
  apiKey,
  mapId,
  mapType,
  layers,
  borders,
  safetyZones,
  incidents,
  devices,
  userLocation,
  userAccuracy,
  selectedBorder,
  onSelectBorder,
  onSelectIncident,
  routeInfo,
  selectedPlace,
  onMapClick,
  centerTarget,
}: GoogleMapViewProps) {
  const defaultCenter = { lat: 10.35, lng: 78.25 };

  return (
    <APIProvider apiKey={apiKey} libraries={['places', 'geometry', 'marker']}>
      <div className="w-full h-full relative">
        <Map
          defaultCenter={defaultCenter}
          defaultZoom={9}
          mapId={mapId || 'bsas_live_ops_map'}
          gestureHandling="greedy"
          disableDefaultUI={true}
          style={{ width: '100%', height: '100%' }}
          internalUsageAttributionIds={['gmp_git_agentskills_v1']}
        >
          <MapInternalController
            mapType={mapType}
            showTraffic={layers.traffic}
            routeInfo={layers.route ? routeInfo : null}
            selectedPlace={selectedPlace}
            centerTarget={centerTarget}
            onMapClick={onMapClick}
          />

          {/* Border Demarcation Layer */}
          <BorderLayer
            borders={borders}
            visible={layers.borders}
            selectedBorderId={selectedBorder?.properties?.id}
            onSelectBorder={onSelectBorder}
          />

          {/* Safety Buffer Zones Layer */}
          <SafetyZoneLayer
            zones={safetyZones}
            visible={layers.safetyZones}
          />

          {/* Incident Layer */}
          <IncidentLayer
            incidents={incidents}
            visible={layers.incidents}
            onSelectIncident={onSelectIncident}
          />

          {/* Active Field Devices Layer */}
          <DeviceLayer
            devices={devices}
            visible={layers.devices}
          />

          {/* Live User GPS Location Fix */}
          <CurrentLocationMarker
            coords={userLocation}
            accuracy={userAccuracy}
          />
        </Map>
      </div>
    </APIProvider>
  );
}
