"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  AlertTriangle,
  Users,
  FileText,
  Layers,
  MapPin,
  ArrowRight,
  Radio,
  CheckCircle2,
  Clock,
} from "lucide-react";

import { getDashboardStats, getEvents, getZones } from "@/lib/api";
import { DashboardStats, AppEvent, Zone } from "@/lib/types";
import { MetricCard } from "@/components/ui/MetricCard";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { AnimatedContent } from "@/components/reactbits/AnimatedContent";
import { LoadingState } from "@/components/ui/LoadingState";

export default function DashboardOverviewPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [events, setEvents] = useState<AppEvent[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    const loadData = async () => {
      try {
        const [statsData, eventsData, zonesData] = await Promise.all([
          getDashboardStats().catch(() => null),
          getEvents().catch(() => []),
          getZones().catch(() => []),
        ]);

        if (isMounted) {
          if (statsData) setStats(statsData);
          setEvents(eventsData);
          setZones(zonesData);
          setLoading(false);
        }
      } catch (err) {
        console.error("Dashboard overview error:", err);
        if (isMounted) setLoading(false);
      }
    };

    loadData();
    const interval = setInterval(loadData, 10000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, []);

  if (loading || !stats) {
    return (
      <div className="flex-1 p-8">
        <LoadingState label="Polling live operations telemetry..." />
      </div>
    );
  }

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <AnimatedContent distance={12} duration={260}>
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
          <div>
            <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              Tactical Operations Command
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white">
              Operations Overview
            </h1>
            <p className="text-xs text-slate-400 mt-0.5">
              Live status across monitored international borders and active field units
            </p>
          </div>

          <div className="flex items-center gap-3">
            <StatusBadge status={stats.current_risk} />
            <Link
              href="/dashboard/map"
              className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-sky-600 hover:bg-sky-500 text-white text-xs font-semibold shadow-md shadow-sky-600/30 transition-all active:scale-95"
            >
              <span>Open Live Map</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>
      </AnimatedContent>

      {/* 4 Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Active Field Units"
          value={stats.active_users}
          icon={<Users className="w-5 h-5 text-sky-400" />}
          subtitle="Real-time GPS telemetry"
          color="text-sky-400"
        />

        <MetricCard
          title="Open Incidents"
          value={stats.open_incidents}
          icon={<FileText className="w-5 h-5 text-amber-400" />}
          subtitle="Pending field audits"
          color="text-amber-400"
        />

        <MetricCard
          title="Critical Alerts"
          value={stats.critical_alerts}
          icon={<AlertTriangle className="w-5 h-5 text-rose-400" />}
          subtitle="Immediate proximity warnings"
          color={stats.critical_alerts > 0 ? "text-rose-400" : "text-slate-100"}
        />

        <MetricCard
          title="Monitored Zones"
          value={zones.length || 4}
          icon={<Layers className="w-5 h-5 text-emerald-400" />}
          subtitle="Active buffer perimeters"
          color="text-emerald-400"
        />
      </div>

      {/* Magic Bento Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Live Operations Map Preview (2 cols) */}
        <SpotlightCard className="lg:col-span-2 p-6 flex flex-col justify-between min-h-[340px]">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <Radio className="w-4 h-4 text-sky-400 animate-pulse" />
                <h2 className="text-sm font-bold text-white tracking-wide uppercase">
                  Spatial Operations Sector Preview
                </h2>
              </div>
              <span className="text-[11px] text-slate-400 font-mono">
                EPSG:4326 · WGS84
              </span>
            </div>

            {/* Tactical Map Preview / Sector Status Canvas */}
            <div className="relative rounded-2xl overflow-hidden border border-slate-800 bg-slate-950 p-6 min-h-[200px] flex flex-col justify-between bg-tactical-grid">
              <div className="flex flex-wrap gap-2 z-10">
                <span className="px-2.5 py-1 rounded-lg bg-slate-900/90 border border-slate-700/80 text-[11px] font-mono text-slate-300">
                  Sector Alpha-1 · Monitored Line
                </span>
                <span className="px-2.5 py-1 rounded-lg bg-emerald-950/80 border border-emerald-800/80 text-[11px] font-mono text-emerald-300">
                  Buffer Zones: 300m / 1000m / 2000m
                </span>
              </div>

              <div className="my-6 flex items-center justify-center">
                <div className="relative flex items-center justify-center">
                  <div className="w-24 h-24 rounded-full border border-sky-500/20 radar-pulse" />
                  <div className="w-12 h-12 rounded-full border border-sky-400/40 absolute" />
                  <MapPin className="w-6 h-6 text-sky-400 absolute animate-bounce" />
                </div>
              </div>

              <div className="flex items-center justify-between text-xs text-slate-400 z-10">
                <span>Authoritative GeoJSON Overlay Active</span>
                <span className="text-emerald-400 font-semibold flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  Geodesic Turf Engine Ready
                </span>
              </div>
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-slate-800/80 flex items-center justify-between">
            <span className="text-xs text-slate-400">
              Interactive Google Maps, Route Planner & Street View
            </span>
            <Link
              href="/dashboard/map"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-sky-400 hover:text-sky-300 transition-colors"
            >
              <span>Launch Tactical Basemap</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </SpotlightCard>

        {/* System Health & Risk Summary (1 col) */}
        <div className="space-y-6">
          {/* Risk Level Distribution */}
          <SpotlightCard className="p-5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
              Perimeter Risk State
            </h3>
            <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between">
              <div>
                <p className="text-[11px] text-slate-400">Current Threat Matrix</p>
                <p className="text-lg font-bold text-white mt-0.5">{stats.current_risk}</p>
              </div>
              <StatusBadge status={stats.current_risk} />
            </div>

            <div className="mt-4 space-y-2 text-xs">
              <div className="flex justify-between text-slate-400">
                <span>Awareness Zone (&lt; 2000m)</span>
                <span className="text-sky-400 font-semibold">Active</span>
              </div>
              <div className="flex justify-between text-slate-400">
                <span>Warning Zone (&lt; 1000m)</span>
                <span className="text-amber-400 font-semibold">Active</span>
              </div>
              <div className="flex justify-between text-slate-400">
                <span>Critical Zone (&lt; 300m)</span>
                <span className="text-rose-400 font-semibold">Enforced</span>
              </div>
            </div>
          </SpotlightCard>

          {/* System Services Readiness */}
          <SpotlightCard className="p-5">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
              System Services Status
            </h3>
            <div className="space-y-2 text-xs">
              <div className="flex items-center justify-between p-2 rounded-lg bg-slate-950/40 border border-slate-800/80">
                <span className="text-slate-300">FastAPI Telemetry Hub</span>
                <span className="text-emerald-400 font-semibold flex items-center gap-1 text-[11px]">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  Operational
                </span>
              </div>
              <div className="flex items-center justify-between p-2 rounded-lg bg-slate-950/40 border border-slate-800/80">
                <span className="text-slate-300">Local TFLite Risk Engine</span>
                <span className="text-emerald-400 font-semibold flex items-center gap-1 text-[11px]">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  On-Device
                </span>
              </div>
              <div className="flex items-center justify-between p-2 rounded-lg bg-slate-950/40 border border-slate-800/80">
                <span className="text-slate-300">SQLite Offline Sync</span>
                <span className="text-sky-400 font-semibold flex items-center gap-1 text-[11px]">
                  <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
                  Queue Synced
                </span>
              </div>
            </div>
          </SpotlightCard>
        </div>
      </div>

      {/* Live Operations Timeline */}
      <SpotlightCard className="p-6">
        <div className="flex items-center justify-between pb-4 border-b border-slate-800 mb-4">
          <div>
            <h3 className="text-sm font-bold text-white tracking-wide uppercase">
              Live Operations Timeline
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Chronological log of alerts, telemetry submissions, and security audits
            </p>
          </div>
          <div className="flex items-center text-xs text-emerald-400 font-medium">
            <span className="w-2 h-2 rounded-full bg-emerald-400 mr-2 animate-pulse" />
            Live Polling Active
          </div>
        </div>

        {events.length === 0 ? (
          <div className="text-center py-10 text-xs text-slate-400">
            No recent operational events logged in the current sector window.
          </div>
        ) : (
          <div className="space-y-3">
            {events.slice(0, 6).map((event) => (
              <div
                key={`${event.type}-${event.id}`}
                className="flex items-start gap-3 p-3 rounded-xl bg-slate-950/40 border border-slate-800/80 hover:border-slate-700 transition-colors"
              >
                <div
                  className={`mt-0.5 p-2 rounded-lg shrink-0 ${
                    event.type === "ALERT" && event.severity === "CRITICAL"
                      ? "bg-rose-950/80 text-rose-400 border border-rose-800/80"
                      : event.type === "ALERT"
                      ? "bg-amber-950/80 text-amber-400 border border-amber-800/80"
                      : "bg-sky-950/80 text-sky-400 border border-sky-800/80"
                  }`}
                >
                  {event.type === "ALERT" ? (
                    <AlertTriangle className="w-3.5 h-3.5" />
                  ) : (
                    <FileText className="w-3.5 h-3.5" />
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-xs font-semibold text-white truncate">
                      {event.title}
                    </p>
                    <span className="text-[10px] text-slate-400 flex items-center gap-1 font-mono shrink-0">
                      <Clock className="w-3 h-3" />
                      {new Date(event.timestamp).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                        second: "2-digit",
                      })}
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-400 mt-0.5 line-clamp-1">
                    {event.data || "Operational event recorded"}
                  </p>

                </div>
              </div>
            ))}
          </div>
        )}
      </SpotlightCard>
    </div>
  );
}
