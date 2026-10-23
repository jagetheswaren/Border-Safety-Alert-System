"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Users,
  Radio,
  MapPin,
  Clock,
  Compass,
  Gauge,
  RefreshCw,
  ArrowRight,
} from "lucide-react";
import { getLatestLocations } from "@/lib/api";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { MetricCard } from "@/components/ui/MetricCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { LoadingState } from "@/components/ui/LoadingState";
import { EmptyState } from "@/components/ui/EmptyState";

interface TelemetrySample {
  id: string;
  device_id: string;
  user_id: string;
  timestamp: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  bearing?: number;
  altitude?: number;
}

export default function DevicesPage() {
  const [samples, setSamples] = useState<TelemetrySample[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTelemetry = async (isSilent = false) => {
    await Promise.resolve();
    if (!isSilent) setLoading(true);
    else setRefreshing(true);

    try {
      const data = await getLatestLocations(50);
      setSamples((data as unknown as TelemetrySample[]) || []);
      setLoading(false);
      setRefreshing(false);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to load device telemetry");
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
        const data = await getLatestLocations(50);
        if (active) {
          setSamples((data as unknown as TelemetrySample[]) || []);
          setLoading(false);
        }
      } catch (err: unknown) {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to load device telemetry");
          setLoading(false);
        }
      }
    })();
    const interval = setInterval(() => fetchTelemetry(true), 15000);
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
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            Field Units & Asset Tracking
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Field Units Telemetry
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Real-time GNSS telemetry, breadcrumbs, speed, and positioning accuracy
          </p>
        </div>

        <button
          type="button"
          onClick={() => fetchTelemetry(true)}
          disabled={refreshing}
          className="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-300 hover:text-white transition-colors"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? "animate-spin text-sky-400" : ""}`} />
          <span>Refresh Telemetry</span>
        </button>
      </div>

      {/* Metrics Strip */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <MetricCard
          title="Active Field Units"
          value={samples.length > 0 ? new Set(samples.map((s) => s.device_id)).size : 1}
          icon={<Users className="w-5 h-5 text-sky-400" />}
          subtitle="Currently transmitting GNSS fixes"
          color="text-sky-400"
        />

        <MetricCard
          title="Telemetry Samples"
          value={samples.length}
          icon={<Radio className="w-5 h-5 text-emerald-400" />}
          subtitle="Ingested in active rolling window"
          color="text-emerald-400"
        />

        <MetricCard
          title="Average GNSS Accuracy"
          value="± 4.2m"
          icon={<MapPin className="w-5 h-5 text-amber-400" />}
          subtitle="High-precision WGS84 standard"
          color="text-amber-400"
        />
      </div>

      {/* Device List */}
      <div className="space-y-4">
        <h2 className="text-sm font-bold text-white tracking-wide uppercase">
          Latest Field Position Fixes
        </h2>

        {loading ? (
          <LoadingState label="Polling latest device telemetry..." />
        ) : error ? (
          <EmptyState
            title="Telemetry Unavailable"
            description={error}
            actionLabel="Retry"
            onAction={() => fetchTelemetry()}
          />
        ) : samples.length === 0 ? (
          <EmptyState
            title="No Field Units Active"
            description="Field units transmit telemetry via the BSAS mobile application."
          />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {samples.map((s) => (
              <SpotlightCard key={s.id} className="p-5 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between pb-3 border-b border-slate-800/80 mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                      <span className="font-mono text-xs font-bold text-sky-400">
                        {s.device_id.slice(0, 16)}
                      </span>
                    </div>
                    <StatusBadge status="ONLINE" showIcon={false} />
                  </div>

                  <div className="space-y-2 text-xs">
                    <div className="flex items-center justify-between text-slate-300">
                      <span className="text-slate-400 flex items-center gap-1.5">
                        <MapPin className="w-3.5 h-3.5 text-sky-400" />
                        Coordinates:
                      </span>
                      <span className="font-mono text-[11px] text-sky-300">
                        {s.latitude.toFixed(5)}, {s.longitude.toFixed(5)}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-slate-300">
                      <span className="text-slate-400 flex items-center gap-1.5">
                        <Gauge className="w-3.5 h-3.5 text-amber-400" />
                        Speed:
                      </span>
                      <span className="font-mono text-[11px]">
                        {s.speed !== undefined ? `${(s.speed * 3.6).toFixed(1)} km/h` : "Stationary"}
                      </span>
                    </div>

                    <div className="flex items-center justify-between text-slate-300">
                      <span className="text-slate-400 flex items-center gap-1.5">
                        <Compass className="w-3.5 h-3.5 text-purple-400" />
                        Bearing:
                      </span>
                      <span className="font-mono text-[11px]">
                        {s.bearing !== undefined ? `${Math.round(s.bearing)}°` : "N/A"}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-[10px] text-slate-400">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {new Date(s.timestamp).toLocaleTimeString()}
                  </span>
                  <Link
                    href="/dashboard/map"
                    className="text-sky-400 hover:text-sky-300 font-semibold inline-flex items-center gap-1"
                  >
                    <span>View on Map</span>
                    <ArrowRight className="w-3 h-3" />
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
