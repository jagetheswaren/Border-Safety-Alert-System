"use client";

import React, { useState, useEffect, useRef } from 'react';
import {
  LatLngLiteral,
  PlaceResult,
  BorderFeature,
} from '../types/map.types';
import { useCurrentLocation } from '../hooks/useCurrentLocation';
import { useBorders } from '../hooks/useBorders';
import { useIncidents } from '../hooks/useIncidents';
import { useRoute } from '../hooks/useRoute';
import { useConnectivity } from '../hooks/useConnectivity';
import { useMapLayers } from '../hooks/useMapLayers';

import { GoogleMapView } from './GoogleMapView';
import { OfflineMapView } from './OfflineMapView';
import { MapToolbar } from './MapToolbar';
import { PlaceSearch } from './PlaceSearch';
import { RoutePlanner } from './RoutePlanner';
import { StreetViewPanel } from './StreetViewPanel';
import { BorderMetadataPanel } from './BorderMetadataPanel';
import { LocationSafetyPanel } from './LocationSafetyPanel';
import { MapLegend } from './MapLegend';

interface BSASMapProps {
  initialCenter?: LatLngLiteral;
  initialZoom?: number;
  refreshRevision?: number;
}

export function BSASMap({
  initialCenter = { lat: 10.35, lng: 78.25 },
  refreshRevision = 0,
}: BSASMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [followLocation, setFollowLocation] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isRouteOpen, setIsRouteOpen] = useState(false);
  const [isStreetViewOpen, setIsStreetViewOpen] = useState(false);
  const [selectedPlace, setSelectedPlace] = useState<PlaceResult | null>(null);
  const [centerTarget, setCenterTarget] = useState<LatLngLiteral | null>(initialCenter);
  const [streetViewPosition, setStreetViewPosition] = useState<LatLngLiteral | null>(initialCenter);

  // Read environment API key for Google Maps Platform
  const googleMapsApiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '';
  const googleMapId = process.env.NEXT_PUBLIC_GOOGLE_MAP_ID || '';
  const isKeyConfigured = Boolean(googleMapsApiKey.trim());

  // Spatial & Telemetry Hooks
  const {
    coords: userCoords,
    accuracy: userAccuracy,
    timestamp: locationTimestamp,
    isLoading: isLocating,
    error: locationError,
    tracking,
    stopTracking,
    requestLocation,
  } = useCurrentLocation(false);

  const {
    borders,
    safetyZones,
    selectedBorder,
    setSelectedBorder,
    refreshBorders,
    error: bordersError,
  } = useBorders(userCoords);

  const {
    incidents,
    devices,
    refreshIncidents,
    error: incidentsError,
  } = useIncidents(30000);

  const {
    origin,
    destination,
    originName,
    destinationName,
    routeInfo,
    isLoading: isRouteLoading,
    error: routeError,
    setOriginPoint,
    setDestinationPoint,
    swapOriginDestination,
    clearRoute,
  } = useRoute();

  const {
    activeProvider,
    toggleProvider,
    checkConnectivity,
  } = useConnectivity();

  const {
    layers,
    mapType,
    toggleLayer,
    setMapType,
  } = useMapLayers();

  useEffect(() => {
    let active = true;
    if (refreshRevision > 0) queueMicrotask(() => {
      if (active) { void refreshBorders(); void refreshIncidents(); }
    });
    return () => { active = false; };
  }, [refreshRevision, refreshBorders, refreshIncidents]);

  // Fullscreen change listener
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(Boolean(document.fullscreenElement));
    };
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
  }, []);

  const handleToggleFullscreen = () => {
    if (!containerRef.current) return;
    if (!document.fullscreenElement) {
      containerRef.current.requestFullscreen().catch((err) => {
        console.error('Fullscreen request error:', err);
      });
    } else {
      document.exitFullscreen().catch((err) => {
        console.error('Exit fullscreen error:', err);
      });
    }
  };

  // Locate User Button Handler
  const handleLocateUser = () => {
    setFollowLocation(true);
    requestLocation();
    if (userCoords) {
      setCenterTarget(userCoords);
      setStreetViewPosition(userCoords);
    }
  };



  // Place search selection handler
  const handlePlaceSelect = (place: PlaceResult) => {
    setFollowLocation(false);
    setSelectedPlace(place);
    setCenterTarget(place.location);
    setStreetViewPosition(place.location);
    setIsSearchOpen(false);

    // If route planner is active and waiting for a destination, populate it
    if (isRouteOpen) {
      if (!origin && userCoords) {
        setOriginPoint(userCoords, 'Current GPS Location');
        setDestinationPoint(place.location, place.name);
      } else if (!destination) {
        setDestinationPoint(place.location, place.name);
      }
    }
  };

  // Map Click Handler for Street View / Pin Routing
  const handleMapClick = (latLng: LatLngLiteral) => {
    setStreetViewPosition(latLng);

    // If route planner is open, update destination or origin
    if (isRouteOpen) {
      if (!origin) {
        setOriginPoint(latLng, `Pin (${latLng.lat.toFixed(4)}, ${latLng.lng.toFixed(4)})`);
      } else if (!destination) {
        setDestinationPoint(latLng, `Pin (${latLng.lat.toFixed(4)}, ${latLng.lng.toFixed(4)})`);
      }
    }
  };

  // Select Border Handler
  const handleSelectBorder = (border: BorderFeature) => {
    setSelectedBorder(border);
  };

  // Refresh all live data
  const handleRefreshData = () => {
    refreshBorders();
    refreshIncidents();
    checkConnectivity();
  };

  // Effective provider: if key is not configured, use the key-free Leaflet map
  const effectiveProvider = isKeyConfigured ? activeProvider : 'offline';
  const effectiveCenter = followLocation && userCoords ? userCoords : centerTarget || initialCenter;
  const effectiveStreetViewPos = streetViewPosition || userCoords || initialCenter;

  return (
    <div
      ref={containerRef}
      className="w-full h-full relative overflow-hidden bg-gray-950 font-sans select-none"
    >
      {/* Operational Toolbar */}
      <MapToolbar
        mapType={mapType}
        onChangeMapType={setMapType}
        layers={layers}
        onToggleLayer={toggleLayer}
        onLocateUser={handleLocateUser}
        isLocating={isLocating}
        onToggleSearch={() => setIsSearchOpen((prev) => !prev)}
        isSearchOpen={isSearchOpen}
        onToggleRoute={() => setIsRouteOpen((prev) => !prev)}
        isRouteOpen={isRouteOpen}
        onToggleStreetView={() => setIsStreetViewOpen((prev) => !prev)}
        isStreetViewOpen={isStreetViewOpen}
        activeProvider={effectiveProvider}
        onToggleProvider={toggleProvider}
        onRefreshData={handleRefreshData}
        isFullscreen={isFullscreen}
        onToggleFullscreen={handleToggleFullscreen}
      />

      {/* Top Search Bar (when toggled) */}
      {isSearchOpen && (
        <div className="absolute top-18 left-6 z-30 w-80 sm:w-96 animate-in fade-in slide-in-from-top-2">
          <PlaceSearch onPlaceSelect={handlePlaceSelect} />
        </div>
      )}

      <LocationSafetyPanel coords={userCoords} timestamp={locationTimestamp} accuracy={userAccuracy} zones={safetyZones} tracking={tracking} error={locationError} isLocating={isLocating} requestLocation={handleLocateUser} stopTracking={stopTracking} />
      {(bordersError || incidentsError) && <div role="alert" className="absolute top-28 left-3 z-30 max-w-sm rounded-xl bg-rose-950 p-3 text-xs text-rose-200">Map data unavailable or outdated: {bordersError || incidentsError}<button className="ml-2 underline" onClick={handleRefreshData}>Retry data</button></div>}
      {/* Active Map Engine */}
      {effectiveProvider === 'google' ? (
        <GoogleMapView
          apiKey={googleMapsApiKey}
          mapId={googleMapId}
          mapType={mapType}
          layers={layers}
          borders={borders}
          safetyZones={safetyZones}
          incidents={incidents}
          devices={devices}
          userLocation={userCoords}
          userAccuracy={userAccuracy}
          selectedBorder={selectedBorder}
          onSelectBorder={handleSelectBorder}
          routeInfo={routeInfo}
          selectedPlace={selectedPlace}
          onMapClick={handleMapClick}
          centerTarget={effectiveCenter}
        />
      ) : (
        <OfflineMapView
          mapType={mapType}
          layers={layers}
          borders={borders}
          safetyZones={safetyZones}
          incidents={incidents}
          devices={devices}
          userLocation={userCoords}
          userAccuracy={userAccuracy}
          selectedBorder={selectedBorder}
          onSelectBorder={handleSelectBorder}
          centerTarget={effectiveCenter}
        />
      )}

      {/* Navigational Route Planner Panel */}
      <RoutePlanner
        routeInfo={routeInfo}
        originName={originName}
        destinationName={destinationName}
        isLoading={isRouteLoading}
        error={routeError}
        onSwap={swapOriginDestination}
        onClear={clearRoute}
        onUseCurrentLocationAsOrigin={
          userCoords
            ? () => setOriginPoint(userCoords, 'Current GPS Position')
            : undefined
        }
        isOpen={isRouteOpen}
        onClose={() => setIsRouteOpen(false)}
      />

      {/* 360° Interactive Street View Panorama Panel */}
      <StreetViewPanel
        position={effectiveStreetViewPos}
        isOpen={isStreetViewOpen}
        onClose={() => setIsStreetViewOpen(false)}
      />

      {/* Clicked Boundary Details Panel */}
      <BorderMetadataPanel
        border={selectedBorder}
        userLocation={userCoords}
        onClose={() => setSelectedBorder(null)}
        onCenterBoundary={(b) => {
          if (b.geometry?.type === 'LineString' && b.geometry.coordinates?.length > 0) {
            const rawCoords = b.geometry.coordinates as unknown as [number, number][];
            const firstCoord = rawCoords[0];
            if (firstCoord && typeof firstCoord[0] === 'number' && typeof firstCoord[1] === 'number') {
              setCenterTarget({ lat: firstCoord[1], lng: firstCoord[0] });
            }
          }
        }}
      />

      {/* Operational Map Legend */}
      {layers.legend && <MapLegend />}
    </div>
  );
}

export default BSASMap;
