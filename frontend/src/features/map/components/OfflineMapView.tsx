"use client";

import { useEffect, useState } from 'react';
import { MapContainer, ZoomControl, TileLayer, GeoJSON, Polygon, Circle, CircleMarker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { MapTypeMode, LatLngLiteral, BorderFeature, SafetyZoneFeature, IncidentMarkerItem, DeviceMarkerItem, MapLayersVisibility } from '../types/map.types';

interface OfflineMapViewProps {
  mapType: MapTypeMode;
  layers: MapLayersVisibility;
  borders: BorderFeature[];
  safetyZones: SafetyZoneFeature[];
  incidents: IncidentMarkerItem[];
  devices: DeviceMarkerItem[];
  userLocation: LatLngLiteral | null;
  userAccuracy?: number | null;
  selectedBorder: BorderFeature | null;
  onSelectBorder?: (border: BorderFeature) => void;
  centerTarget?: LatLngLiteral | null;
}

function Viewport({ target }: { target?: LatLngLiteral | null }) {
  const map = useMap();
  useEffect(() => {
    if (target) map.flyTo([target.lat, target.lng], map.getZoom(), { duration: 0.6 });
  }, [map, target]);
  useEffect(() => {
    const observer = new ResizeObserver(() => map.invalidateSize());
    observer.observe(map.getContainer());
    return () => observer.disconnect();
  }, [map]);
  return null;
}

function valid(lat: number, lng: number) { return Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat) <= 90 && Math.abs(lng) <= 180; }

/** Existing key-free map surface. Uses online tiles; does not promise offline caching. */
export function OfflineMapView({ mapType, layers, borders, safetyZones, incidents, devices, userLocation, userAccuracy, selectedBorder, onSelectBorder, centerTarget }: OfflineMapViewProps) {
  const [tileError, setTileError] = useState(false);
  const satellite = mapType === 'satellite' || mapType === 'hybrid';
  return <div className="w-full h-full min-h-[400px] relative">
    <MapContainer className="bsas-live-map" zoomControl={false} center={centerTarget ? [centerTarget.lat, centerTarget.lng] : [10.35, 78.25]} zoom={9} minZoom={2} maxZoom={19} style={{ height: '100%', width: '100%', minHeight: 400, zIndex: 0 }}>
      <ZoomControl position="topright" />
      <Viewport target={centerTarget} />
      <TileLayer key={satellite ? 'satellite' : 'street'}
        url={satellite ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'}
        attribution={satellite ? '&copy; Esri, Maxar, Earthstar Geographics' : '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'}
        maxNativeZoom={satellite ? 18 : 19}
        eventHandlers={{ tileerror: () => setTileError(true), tileload: () => setTileError(false) }} />
      {mapType === 'hybrid' && <TileLayer url="https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}" attribution="&copy; Esri" />}
      {layers.borders && borders.map(border => <GeoJSON key={JSON.stringify(border)} data={border as unknown as GeoJSON.Feature} style={{ color: '#ef4444', weight: 3, fillOpacity: 0 }} eventHandlers={{ click: () => onSelectBorder?.(border) }} />)}
      {layers.safetyZones && safetyZones.map(zone => <Polygon key={zone.id} positions={zone.rings ?? [zone.coordinates]} pathOptions={{ color: zone.color, fillOpacity: zone.fillOpacity }}><Popup>{zone.name} · {zone.severity}</Popup></Polygon>)}
      {layers.incidents && incidents.filter(i => valid(i.latitude, i.longitude)).map(i => <CircleMarker key={i.id} center={[i.latitude, i.longitude]} radius={7} pathOptions={{ color: 'white', fillColor: '#ef4444', fillOpacity: 1, weight: 2 }}><Popup>{i.title} · {i.severity} · {i.status}</Popup></CircleMarker>)}
      {layers.devices && devices.filter(d => valid(d.latitude, d.longitude)).map(d => <CircleMarker key={d.id} center={[d.latitude, d.longitude]} radius={6} pathOptions={{ color: 'white', fillColor: '#10b981', fillOpacity: 1, weight: 2 }}><Popup>Unit {d.deviceId}</Popup></CircleMarker>)}
      {userLocation && <>
        {userAccuracy != null && <Circle center={[userLocation.lat, userLocation.lng]} radius={userAccuracy} pathOptions={{ color: '#3b82f6', weight: 2, fillOpacity: 0.12 }} />}
        <CircleMarker center={[userLocation.lat, userLocation.lng]} radius={8} pathOptions={{ color: 'white', fillColor: '#2563eb', fillOpacity: 1, weight: 3 }}><Popup>Your device location · accuracy ±{userAccuracy?.toFixed(0) ?? '?'} m</Popup></CircleMarker>
      </>}
    </MapContainer>
    {tileError && <div role="alert" className="absolute top-36 right-3 z-20 rounded bg-rose-950 p-3 text-xs text-rose-200">Some map tiles could not load. Check your connection and retry.</div>}
    <div className="absolute top-28 right-3 z-10 max-w-xs rounded bg-slate-950/85 p-2 text-[10px] text-amber-200 pointer-events-none">Configured boundaries · unverified for navigation{selectedBorder ? ` · ${selectedBorder.properties.boundary_name}` : ''}</div>
  </div>;
}
