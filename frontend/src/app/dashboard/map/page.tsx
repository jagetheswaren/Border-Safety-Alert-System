"use client";

import React, { useEffect, useState, useCallback } from "react";
import dynamic from "next/dynamic";
import { getZones, getIncidents, getAlerts } from "@/lib/api";
import { Zone, Incident, Alert } from "@/lib/types";
import { RefreshCw, MapPin, Shield, AlertTriangle } from "lucide-react";
import { LoadingState } from "@/components/ui/LoadingState";

// Dynamically import BSASMap to disable SSR for window/canvas/map engines
const BSASMap = dynamic(
  () => import("@/features/map/components/BSASMap").then((mod) => mod.BSASMap),
  {
    ssr: false,
    loading: () => (
      <div className="w-full h-full flex items-center justify-center bg-slate-950">
        <LoadingState label="Initializing High-Precision Spatial Mapping & Telemetry Engine..." />
      </div>
    ),
  }
);

export default function LiveMapPage() {
  const [refreshRevision, setRefreshRevision] = useState(0);
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
        getZones(),
        getIncidents({ limit: 50 }),
        getAlerts({ limit: 50 }),
      ]);

      setZones(zonesData);
      setIncidents(incidentsRes.items);
      setAlerts(alertsRes.items);
    } catch (err: unknown) {
      console.error("Map page data load error:", err);
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
          getZones(),
          getIncidents({ limit: 50 }),
          getAlerts({ limit: 50 }),
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
    <div className="flex-1 flex flex-col h-[calc(100vh-3.5rem)] bg-slate-950 p-2 sm:p-3 overflow-hidden select-none">
      {/* Tactical Sub-Header */}
      <div className="mb-2 px-1 flex flex-wrap justify-between items-center gap-2">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <h1 className="text-xs sm:text-sm font-bold text-white tracking-wide uppercase">
            Live Operations Spatial Map
          </h1>
          <span className="text-[11px] text-slate-400 font-mono hidden md:inline">
            · Street and satellite maps · configured safety boundaries
          </span>
        </div>

        <div className="flex items-center gap-2">
          <div className="hidden sm:flex items-center gap-2.5 text-xs bg-slate-900 border border-slate-800 rounded-xl px-2.5 py-1 shadow-sm">
            <span className="flex items-center text-slate-300 text-[11px]">
              <Shield className="w-3 h-3 text-sky-400 mr-1" />
              {zones.length} Zones
            </span>
            <span className="text-slate-700">•</span>
            <span className="flex items-center text-slate-300 text-[11px]">
              <MapPin className="w-3 h-3 text-amber-400 mr-1" />
              {incidents.length} Incidents
            </span>
            <span className="text-slate-700">•</span>
            <span className="flex items-center text-slate-300 text-[11px]">
              <AlertTriangle className="w-3 h-3 text-rose-400 mr-1" />
              {alerts.length} Alerts
            </span>
          </div>

          <button
            type="button"
            onClick={() => { void loadMapData(); setRefreshRevision(r => r + 1); }}
            disabled={isLoading}
            className="flex items-center text-xs bg-slate-900 hover:bg-slate-800 text-slate-200 border border-slate-700/80 rounded-xl px-3 py-1 transition-colors disabled:opacity-50"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 mr-1.5 ${isLoading ? "animate-spin text-sky-400" : ""}`}
            />
            <span className="text-[11px] font-medium">Refresh</span>
          </button>
        </div>
      </div>

      {/* 90% Viewport Map Canvas */}
      <div className="flex-1 min-h-[400px] rounded-2xl border border-slate-800 bg-slate-900 overflow-hidden relative shadow-2xl">
        {error && (
          <div className="absolute top-3 left-1/2 -translate-x-1/2 z-50 bg-rose-950/90 border border-rose-800 text-rose-300 px-4 py-2 rounded-xl text-xs flex items-center space-x-2 shadow-2xl backdrop-blur-md">
            <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0" />
            <span>{error}</span>
          </div>
        )}
        <BSASMap refreshRevision={refreshRevision} />
      </div>
    </div>
  );
}
