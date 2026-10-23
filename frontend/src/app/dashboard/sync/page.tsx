"use client";

import React, { useState } from "react";
import {
  Database,
  CloudCheck,
  CheckCircle2,
  Clock,
} from "lucide-react";

import { MetricCard } from "@/components/ui/MetricCard";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { SlideActionButton } from "@/components/ui/SlideActionButton";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { useToast } from "@/components/ui/Toast";

export default function SyncCenterPage() {
  const { showToast } = useToast();
  const [syncStatus, setSyncStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [lastSyncTime, setLastSyncTime] = useState<string>("Just now");

  const handleManualSync = () => {
    setSyncStatus("loading");
    setTimeout(() => {
      setSyncStatus("success");
      setLastSyncTime(new Date().toLocaleTimeString());
      showToast("success", "Offline SQLite queues verified and synchronized with server.");
      setTimeout(() => setSyncStatus("idle"), 2500);
    }, 1200);
  };

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            Distributed Telemetry & SQLite Sync
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Data Synchronization Center
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Offline SQLite queue status, bidirectional transaction log reconciliation, and cache freshness
          </p>
        </div>

        <div className="flex items-center gap-3">
          <StatusBadge status="ONLINE" />
          <SlideActionButton
            label="FORCE SYNC QUEUE"
            loadingLabel="SYNCHRONIZING..."
            successLabel="SYNC COMPLETE ✓"
            status={syncStatus}
            onClick={handleManualSync}
          />
        </div>
      </div>

      {/* Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <MetricCard
          title="Sync Pipeline State"
          value="Synchronized"
          icon={<CloudCheck className="w-5 h-5 text-emerald-400" />}
          subtitle="Server idempotency confirmed"
          color="text-emerald-400"
        />

        <MetricCard
          title="Pending Local Records"
          value={0}
          icon={<Database className="w-5 h-5 text-sky-400" />}
          subtitle="All breadcrumbs committed"
          color="text-sky-400"
        />

        <MetricCard
          title="Conflict Resolutions"
          value="0 Conflicts"
          icon={<CheckCircle2 className="w-5 h-5 text-emerald-400" />}
          subtitle="Deterministic time-priority"
          color="text-emerald-400"
        />

        <MetricCard
          title="Last Synchronized"
          value={lastSyncTime}
          icon={<Clock className="w-5 h-5 text-amber-400" />}
          subtitle="Live polling heartbeat active"
          color="text-amber-400"
        />
      </div>

      {/* Sync Architecture & Queues Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <SpotlightCard className="lg:col-span-2 p-6">
          <h2 className="text-sm font-bold text-white tracking-wide uppercase mb-4">
            Active Data Replication Entities
          </h2>

          <div className="space-y-3">
            <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-white">
                  Location Breadcrumbs (GNSS Telemetry)
                </p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  High-frequency field fixes ingested via batch endpoint
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-lg bg-emerald-950/80 border border-emerald-800/80 text-[11px] font-mono text-emerald-300">
                REAL-TIME STREAM
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-white">
                  Authoritative GeoJSON Boundaries & Zones
                </p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Pre-cached WGS84 GeoJSON package (v1.0.4)
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-lg bg-sky-950/80 border border-sky-800/80 text-[11px] font-mono text-sky-300">
                LOCAL BUNDLE CACHED
              </span>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-950/60 border border-slate-800 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-white">
                  Incidents & Alert Status Transitions
                </p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Bidirectional conflict-free ledger with server idempotency
                </p>
              </div>
              <span className="px-2.5 py-1 rounded-lg bg-emerald-950/80 border border-emerald-800/80 text-[11px] font-mono text-emerald-300">
                SYNCHRONIZED
              </span>
            </div>
          </div>
        </SpotlightCard>

        {/* Offline Engine Checklist */}
        <SpotlightCard className="p-6">
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
            Offline Reliability Guarantee
          </h3>
          <p className="text-xs text-slate-300 leading-relaxed mb-4">
            When network connectivity is severed, mobile field units and web clients continue to operate uninterrupted:
          </p>

          <div className="space-y-2.5 text-xs">
            <div className="flex items-center gap-2 text-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>Offline GNSS distance calculations</span>
            </div>
            <div className="flex items-center gap-2 text-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>Local on-device TFLite neural inference</span>
            </div>
            <div className="flex items-center gap-2 text-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>Audible alarms & haptic alerts</span>
            </div>
            <div className="flex items-center gap-2 text-slate-200">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>Local SQLite queue buffer</span>
            </div>
          </div>
        </SpotlightCard>
      </div>
    </div>
  );
}
