"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Layers,
  Shield,
  AlertTriangle,
  AlertCircle,
  ArrowRight,
} from "lucide-react";
import { getZones } from "@/lib/api";
import { Zone } from "@/lib/types";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";

import { LoadingState } from "@/components/ui/LoadingState";
import { EmptyState } from "@/components/ui/EmptyState";

export default function SafetyZonesPage() {
  const [zones, setZones] = useState<Zone[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getZones()
      .then((data) => {
        if (active) {
          setZones(data || []);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to load safety zones");
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
            Geofencing & Safety Thresholds
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Monitored Safety Zones
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Buffer distances, multi-tier warning thresholds, and active border sector configurations
          </p>
        </div>

        <Link
          href="/dashboard/map"
          className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-sky-600 hover:bg-sky-500 text-white text-xs font-semibold shadow-md shadow-sky-600/30 transition-all active:scale-95"
        >
          <span>View Zones on Map</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>

      {/* Threshold Hierarchy Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <SpotlightCard className="p-5 border-rose-900/60 bg-slate-900/80">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 rounded-xl bg-rose-950 text-rose-400 border border-rose-800/60">
              <AlertCircle className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-rose-400">
                Critical Zone
              </p>
              <p className="text-xl font-extrabold text-white mt-0.5">&lt; 300 meters</p>
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-2 leading-relaxed">
            Immediate boundary proximity. Triggers urgent audible siren, haptic vibration, and emergency operator notification.
          </p>
        </SpotlightCard>

        <SpotlightCard className="p-5 border-amber-900/60 bg-slate-900/80">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 rounded-xl bg-amber-950 text-amber-400 border border-amber-800/60">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-amber-400">
                Warning Zone
              </p>
              <p className="text-xl font-extrabold text-white mt-0.5">&lt; 1,000 meters</p>
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-2 leading-relaxed">
            Intermediate buffer boundary. Triggers voice guidance and proactive course correction guidance.
          </p>
        </SpotlightCard>

        <SpotlightCard className="p-5 border-sky-900/60 bg-slate-900/80">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 rounded-xl bg-sky-950 text-sky-400 border border-sky-800/60">
              <Shield className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-sky-400">
                Awareness Zone
              </p>
              <p className="text-xl font-extrabold text-white mt-0.5">&lt; 2,000 meters</p>
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-2 leading-relaxed">
            Perimeter monitoring entry point. Initiates high-rate GPS tracking and on-device LSTM trajectory evaluation.
          </p>
        </SpotlightCard>
      </div>

      {/* Configured Border Sectors */}
      <div className="space-y-4">
        <h2 className="text-sm font-bold text-white tracking-wide uppercase">
          Configured Sector Polygons & Geometry
        </h2>

        {loading ? (
          <LoadingState label="Loading zone specifications..." />
        ) : error ? (
          <EmptyState
            title="Failed to Load Zones"
            description={error}
          />
        ) : zones.length === 0 ? (
          <EmptyState
            title="No Border Sectors Found"
            description="Run database seeder or check boundary configuration."
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {zones.map((zone) => (
              <SpotlightCard key={zone.id} className="p-5 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800/80 mb-3">
                    <div className="flex items-center gap-2">
                      <Layers className="w-4 h-4 text-sky-400" />
                      <h3 className="text-sm font-bold text-white">{zone.name}</h3>
                    </div>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-950 border border-emerald-800 text-emerald-400">
                      ACTIVE BUFFER
                    </span>
                  </div>

                  <p className="text-xs text-slate-300 leading-relaxed mb-4">
                    Border safety sector configured with multi-tier geodesic buffer zones. Risk Profile: {zone.severity}.
                  </p>

                  <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 space-y-2 text-xs">
                    <div className="flex justify-between text-slate-400">
                      <span>Critical Buffer:</span>
                      <span className="font-mono text-rose-400 font-bold">
                        300m
                      </span>
                    </div>
                    <div className="flex justify-between text-slate-400">
                      <span>Warning Buffer:</span>
                      <span className="font-mono text-amber-400 font-bold">
                        {zone.warning_radius_m || 1000}m
                      </span>
                    </div>
                    <div className="flex justify-between text-slate-400">
                      <span>Awareness Buffer:</span>
                      <span className="font-mono text-sky-400 font-bold">
                        2000m
                      </span>
                    </div>
                  </div>
                </div>


                <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-[11px] text-slate-400">
                  <span>Authoritative GIS Boundary ID: {zone.id}</span>
                  <Link
                    href="/dashboard/map"
                    className="text-sky-400 hover:text-sky-300 font-semibold inline-flex items-center gap-1"
                  >
                    <span>View Polygon</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </SpotlightCard>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
