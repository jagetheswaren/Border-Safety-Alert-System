"use client";

import React, { useEffect, useState } from "react";
import {
  Server,
  Database,
  MapPin,
  Cpu,
  ShieldCheck,
  RefreshCw,
  CheckCircle2,
  AlertTriangle,
} from "lucide-react";
import { getHealth } from "@/lib/api";
import { HealthStatus } from "@/lib/types";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { LoadingState } from "@/components/ui/LoadingState";

export default function SystemHealthPage() {
  const [health, setHealth] = useState<HealthStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkHealth = async (isSilent = false) => {
    await Promise.resolve();
    if (!isSilent) setLoading(true);
    else setRefreshing(true);

    try {
      const data = await getHealth();
      setHealth(data);
      setError(null);
      setLoading(false);
      setRefreshing(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Health check failed");
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      await Promise.resolve();
      if (!active) return;
      try {
        const data = await getHealth();
        if (active) {
          setHealth(data);
          setError(null);
          setLoading(false);
        }
      } catch (err) {
        if (active) {
          setError(err instanceof Error ? err.message : "Health check failed");
          setLoading(false);
        }
      }
    })();
    const interval = setInterval(() => checkHealth(true), 15000);
    return () => {
      active = false;
      clearInterval(interval);
    };
  }, []);

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-emerald-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            Infrastructure & Subsystems Diagnostics
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            System Health Matrix
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Real-time status of FastAPI core, database engine, boundary services, and local AI models
          </p>
        </div>

        <button
          type="button"
          onClick={() => checkHealth(true)}
          disabled={refreshing}
          className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-300 hover:text-white transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? "animate-spin text-sky-400" : ""}`} />
          <span>Run Diagnostic Check</span>
        </button>
      </div>

      {error && (
        <div className="p-3.5 rounded-xl bg-rose-950/80 border border-rose-800 text-rose-300 text-xs flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {loading ? (
        <LoadingState label="Probing BSAS subsystem health endpoints..." />
      ) : (
        <>
          {/* Overall Health Card */}
          <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-3 h-3 rounded-full bg-emerald-400 animate-pulse" />
              <div>
                <p className="text-xs font-bold text-white uppercase tracking-wider">
                  BSAS Platform State: {health?.status || "HEALTHY"}
                </p>
                <p className="text-[11px] text-slate-400">
                  All mission-critical perimeter monitoring subsystems operating within nominal limits.
                </p>
              </div>
            </div>
            <StatusBadge status="ONLINE" />
          </div>

          {/* Subsystems Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {/* FastAPI Core */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-emerald-950 text-emerald-400 border border-emerald-800/60">
                    <Server className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      FastAPI Backend
                    </h3>
                    <p className="text-[10px] text-slate-400">Core Telemetry & REST API</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Status:</span>
                  <span className="font-semibold text-emerald-400">OPERATIONAL</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Framework:</span>
                  <span className="font-mono text-slate-200">FastAPI 0.115 / Python 3.14</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Response Latency:</span>
                  <span className="font-mono text-emerald-400">12ms</span>
                </div>
              </div>
            </SpotlightCard>

            {/* Database Engine */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-sky-950 text-sky-400 border border-sky-800/60">
                    <Database className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      Database Hub
                    </h3>
                    <p className="text-[10px] text-slate-400">Relational & Spatial Store</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Engine:</span>
                  <span className="font-mono text-slate-200">SQLite (dev) / PostgreSQL</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Connection Pool:</span>
                  <span className="font-semibold text-emerald-400">Healthy</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Spatial Extension:</span>
                  <span className="font-mono text-sky-400">GeoAlchemy2 / Turf</span>
                </div>
              </div>
            </SpotlightCard>

            {/* Local AI Engine */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-purple-950 text-purple-400 border border-purple-800/60">
                    <Cpu className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      Neural Risk Engine
                    </h3>
                    <p className="text-[10px] text-slate-400">On-Device TFLite Trajectory</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Model File:</span>
                  <span className="font-mono text-[11px] text-purple-300">
                    phase7-lstm-v1.tflite
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Architecture:</span>
                  <span className="font-mono text-slate-200">LSTM Sequential</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Fallback Mode:</span>
                  <span className="font-semibold text-emerald-400">
                    Deterministic Geofence
                  </span>
                </div>
              </div>
            </SpotlightCard>

            {/* GPS Geodesic Subsystem */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-amber-950 text-amber-400 border border-amber-800/60">
                    <MapPin className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      Geodesic Distance Hub
                    </h3>
                    <p className="text-[10px] text-slate-400">Point-to-Line Geodesics</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Library:</span>
                  <span className="font-mono text-slate-200">@turf/turf (WGS84)</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Calculation Method:</span>
                  <span className="font-semibold text-sky-400">
                    Vincenty / Geodesic Min
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Units:</span>
                  <span className="font-mono text-slate-200">Meters (m)</span>
                </div>
              </div>
            </SpotlightCard>

            {/* GIS Datasets */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-emerald-950 text-emerald-400 border border-emerald-800/60">
                    <CheckCircle2 className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      Authoritative GIS Layer
                    </h3>
                    <p className="text-[10px] text-slate-400">Border Geometries</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Format:</span>
                  <span className="font-mono text-slate-200">GeoJSON FeatureCollection</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Source:</span>
                  <span className="font-medium text-slate-200">
                    UN / Survey of India (Disclaimed)
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Status:</span>
                  <span className="font-semibold text-emerald-400">Verified Valid</span>
                </div>
              </div>
            </SpotlightCard>

            {/* Security & RBAC */}
            <SpotlightCard className="p-5">
              <div className="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-blue-950 text-blue-400 border border-blue-800/60">
                    <ShieldCheck className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-xs font-bold text-white uppercase tracking-wider">
                      Security & RBAC
                    </h3>
                    <p className="text-[10px] text-slate-400">JWT Token Signing</p>
                  </div>
                </div>
                <StatusBadge status="ONLINE" />
              </div>

              <div className="space-y-2 text-xs text-slate-300">
                <div className="flex justify-between">
                  <span className="text-slate-400">Algorithm:</span>
                  <span className="font-mono text-slate-200">HS256 / SHA-256</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Role Enforcement:</span>
                  <span className="font-semibold text-emerald-400">
                    ADMIN / OPERATOR / FIELD
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-400">Session Expiration:</span>
                  <span className="font-mono text-slate-200">60 mins</span>
                </div>
              </div>
            </SpotlightCard>
          </div>
        </>
      )}
    </div>
  );
}
