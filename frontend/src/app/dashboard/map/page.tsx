"use client";

import { useEffect, useState, useCallback } from "react";
import dynamic from "next/dynamic";
import { getZones, getIncidents, getAlerts } from "@/lib/api";
import { Zone, Incident, Alert } from "@/lib/types";
import { RefreshCw, MapPin, Shield, AlertTriangle } from "lucide-react";

// Dynamically import MapComponent to disable SSR for Leaflet
const MapComponent = dynamic(() => import("@/components/MapComponent"), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-900 text-gray-400 text-sm">
      Initializing Interactive Map Tiles...
    </div>
  ),
});

export default function LiveMapPage() {
  const [zones, setZones] = useState<Zone[]>([]);
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadMapData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [zonesData, incidentsRes, alertsRes] = await Promise.all([
        getZones().catch(() => []),
        getIncidents({ limit: 50 }).catch(() => ({ items: [], total: 0, page: 1, size: 50 })),
        getAlerts({ limit: 50 }).catch(() => ({ items: [], total: 0, page: 1, size: 50 })),
      ]);

      setZones(zonesData);
      setIncidents(incidentsRes.items);
      setAlerts(alertsRes.items);
    } catch (err: unknown) {
      console.error(err);
      setError(err instanceof Error ? err.message : "Failed to load live map data");
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;
    (async () => {
      try {
        const [zonesData, incidentsRes, alertsRes] = await Promise.all([
          getZones().catch(() => []),
          getIncidents({ limit: 50 }).catch(() => ({ items: [], total: 0, page: 1, size: 50 })),
          getAlerts({ limit: 50 }).catch(() => ({ items: [], total: 0, page: 1, size: 50 })),
        ]);
        if (isMounted) {
          setZones(zonesData);
          setIncidents(incidentsRes.items);
          setAlerts(alertsRes.items);
          setIsLoading(false);
        }
      } catch (err: unknown) {
        if (isMounted) {
          setError(err instanceof Error ? err.message : "Failed to load live map data");
          setIsLoading(false);
        }
      }
    })();
    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <div className="flex-1 flex flex-col h-full bg-gray-950 p-6">
      <header className="mb-4 flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-white tracking-tight">Live Operations Map</h1>
          <p className="text-gray-400 text-xs mt-0.5">Real-time spatial visualization of border sectors, zones, and field incidents</p>
        </div>

        <div className="flex items-center space-x-4">
          <div className="flex items-center space-x-3 text-xs bg-gray-900 border border-gray-800 rounded-lg px-3 py-1.5">
            <span className="flex items-center text-gray-300">
              <Shield className="w-3.5 h-3.5 text-blue-500 mr-1" />
              {zones.length} Zones
            </span>
            <span className="text-gray-700">•</span>
            <span className="flex items-center text-gray-300">
              <MapPin className="w-3.5 h-3.5 text-yellow-500 mr-1" />
              {incidents.length} Incidents
            </span>
            <span className="text-gray-700">•</span>
            <span className="flex items-center text-gray-300">
              <AlertTriangle className="w-3.5 h-3.5 text-red-500 mr-1" />
              {alerts.length} Alerts
            </span>
          </div>

          <button
            onClick={loadMapData}
            disabled={isLoading}
            className="flex items-center text-xs bg-gray-800 hover:bg-gray-700 text-white rounded-lg px-3 py-1.5 transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 mr-1.5 ${isLoading ? "animate-spin" : ""}`} />
            Refresh
          </button>
        </div>
      </header>

      <div className="flex-1 rounded-xl border border-gray-800 bg-gray-900 overflow-hidden relative shadow-2xl">
        {isLoading && zones.length === 0 ? (
          <div className="absolute inset-0 flex items-center justify-center bg-gray-900/80 z-10 text-gray-400 text-sm">
            Loading live map data...
          </div>
        ) : error ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-900 text-red-400 p-4 z-10">
            <AlertTriangle className="w-8 h-8 mb-2" />
            <p className="font-semibold text-sm">{error}</p>
            <button
              onClick={loadMapData}
              className="mt-3 text-xs bg-red-500/20 hover:bg-red-500/30 text-red-300 px-3 py-1.5 rounded-md border border-red-500/40"
            >
              Retry Connection
            </button>
          </div>
        ) : (
          <MapComponent zones={zones} incidents={incidents} alerts={alerts} />
        )}
      </div>
    </div>
  );
}
