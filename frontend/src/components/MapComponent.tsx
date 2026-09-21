"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Polygon, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { Zone, Incident, Alert, GeoJSONGeometry } from "@/lib/types";
import Link from "next/link";
import { AlertTriangle, Shield, FileText } from "lucide-react";

// Fix Leaflet default icon paths for Next.js bundle
const DefaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

L.Marker.prototype.options.icon = DefaultIcon;

interface MapComponentProps {
  zones: Zone[];
  incidents: Incident[];
  alerts: Alert[];
}

function HelperFitBounds({ zones, incidents }: { zones: Zone[]; incidents: Incident[] }) {
  const map = useMap();

  useEffect(() => {
    const points: [number, number][] = [];

    zones.forEach((z) => {
      try {
        const geo: GeoJSONGeometry = typeof z.geometry === "string" ? JSON.parse(z.geometry) : z.geometry;
        if (geo && geo.type === "Polygon" && Array.isArray(geo.coordinates)) {
          const ring = geo.coordinates[0] as number[][];
          ring.forEach((pt) => {
            if (Array.isArray(pt) && pt.length >= 2) {
              points.push([pt[1], pt[0]]);
            }
          });
        }
      } catch (e) {
        console.error("Failed to parse zone geometry", e);
      }
    });

    incidents.forEach((inc) => {
      if (inc.latitude && inc.longitude) {
        points.push([inc.latitude, inc.longitude]);
      }
    });

    if (points.length > 0) {
      const bounds = L.latLngBounds(points);
      map.fitBounds(bounds, { padding: [40, 40] });
    }
  }, [zones, incidents, map]);

  return null;
}

export default function MapComponent({ zones, incidents, alerts }: MapComponentProps) {
  const defaultCenter: [number, number] = [10.25, 78.35];

  const getZoneColor = (severity: string, type: string) => {
    const sev = severity?.toUpperCase();
    const t = type?.toUpperCase();
    if (sev === "CRITICAL" || t === "RESTRICTED") return "#ef4444";
    if (sev === "HIGH" || t === "WARNING") return "#f59e0b";
    if (sev === "MEDIUM" || t === "MONITORING") return "#3b82f6";
    return "#10b981";
  };

  return (
    <div className="w-full h-full relative">
      <MapContainer
        center={defaultCenter}
        zoom={10}
        style={{ width: "100%", height: "100%", background: "#090d16" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <HelperFitBounds zones={zones} incidents={incidents} />

        {/* Zone Polygons */}
        {zones.map((zone) => {
          try {
            const geo: GeoJSONGeometry = typeof zone.geometry === "string" ? JSON.parse(zone.geometry) : zone.geometry;
            if (!geo || geo.type !== "Polygon" || !Array.isArray(geo.coordinates)) return null;

            const polygonRing = geo.coordinates[0] as number[][];
            const positions: [number, number][] = polygonRing.map((pt) => [pt[1], pt[0]]);
            const color = getZoneColor(zone.severity, zone.type);

            return (
              <Polygon
                key={zone.id}
                positions={positions}
                pathOptions={{
                  color,
                  fillColor: color,
                  fillOpacity: 0.3,
                  weight: 2,
                  dashArray: zone.type === "WARNING" ? "6, 6" : undefined,
                }}
              >
                <Popup className="zone-popup">
                  <div className="p-2 space-y-1">
                    <div className="flex items-center text-xs font-semibold text-gray-800">
                      <Shield className="w-3.5 h-3.5 mr-1 text-blue-600" />
                      {zone.name}
                    </div>
                    <div className="text-xs text-gray-600">
                      Type: <span className="font-medium text-gray-900">{zone.type}</span>
                    </div>
                    <div className="text-xs text-gray-600">
                      Severity: <span className="font-semibold text-red-600">{zone.severity}</span>
                    </div>
                  </div>
                </Popup>
              </Polygon>
            );
          } catch (e) {
            console.error("Error rendering zone polygon", e);
            return null;
          }
        })}

        {/* Incident Markers */}
        {incidents.map((inc) => {
          if (!inc.latitude || !inc.longitude) return null;
          return (
            <Marker key={inc.id} position={[inc.latitude, inc.longitude]}>
              <Popup>
                <div className="p-2 min-w-[180px]">
                  <div className="flex items-center space-x-1 mb-1">
                    <FileText className="w-4 h-4 text-blue-600" />
                    <span className="font-semibold text-xs text-gray-900">{inc.incident_number || inc.title}</span>
                  </div>
                  <p className="text-xs font-medium text-gray-800">{inc.title}</p>
                  <div className="mt-2 flex items-center justify-between text-[11px]">
                    <span className="px-1.5 py-0.5 rounded bg-red-100 text-red-800 font-medium">
                      {inc.severity}
                    </span>
                    <span className="text-gray-500">{inc.status}</span>
                  </div>
                  <div className="mt-3 text-right">
                    <Link
                      href={`/dashboard/incidents/${inc.id}`}
                      className="text-xs font-medium text-blue-600 hover:underline"
                    >
                      View Details &rarr;
                    </Link>
                  </div>
                </div>
              </Popup>
            </Marker>
          );
        })}

        {/* Alert Markers */}
        {alerts.map((alt) => {
          if (!alt.location_lat || !alt.location_lng) return null;
          return (
            <Marker key={alt.id} position={[alt.location_lat, alt.location_lng]}>
              <Popup>
                <div className="p-2 min-w-[180px]">
                  <div className="flex items-center space-x-1 mb-1 text-red-600">
                    <AlertTriangle className="w-4 h-4" />
                    <span className="font-bold text-xs">{alt.title}</span>
                  </div>
                  <p className="text-xs text-gray-600 mb-2">{alt.message}</p>
                  <div className="text-[10px] text-gray-400">
                    {new Date(alt.created_at).toLocaleString()}
                  </div>
                </div>
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </div>
  );
}
