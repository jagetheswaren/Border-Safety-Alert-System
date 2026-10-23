"use client";

import React, { useEffect, useState } from "react";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  AlertTriangle,
  AlertCircle,
  Clock,
  Check,
  CheckCircle2,
  RefreshCw,
} from "lucide-react";
import { getAlerts, getZones, updateAlertStatus } from "@/lib/api";
import { Alert, Zone, PaginatedResponse } from "@/lib/types";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { PillNav } from "@/components/reactbits/PillNav";
import { ElectricBorder } from "@/components/reactbits/ElectricBorder";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { LoadingState } from "@/components/ui/LoadingState";
import { useToast } from "@/components/ui/Toast";

export default function AlertsListPage() {
  const { showToast } = useToast();
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [search, setSearch] = useState("");
  const [severity, setSeverity] = useState<string>("ALL");
  const [zoneId, setZoneId] = useState("");

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getZones()
      .then((data) => {
        if (active) setZones(data);
      })
      .catch(console.error);
    return () => {
      active = false;
    };
  }, []);

  const fetchAlerts = async (isSilent = false) => {
    await Promise.resolve();
    if (!isSilent) setLoading(true);
    else setRefreshing(true);

    const skip = (page - 1) * pageSize;
    try {
      const res: PaginatedResponse<Alert> = await getAlerts({
        skip,
        limit: pageSize,
        search: search || undefined,
        severity: severity === "ALL" ? undefined : severity,
        zone_id: zoneId || undefined,
      });
      setAlerts(res.items);
      setTotal(res.total);
      setLoading(false);
      setRefreshing(false);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to fetch alerts list");
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      await Promise.resolve();
      if (!active) return;
      setLoading(true);
      const skip = (page - 1) * pageSize;
      try {
        const res = await getAlerts({
          skip,
          limit: pageSize,
          search: search || undefined,
          severity: severity === "ALL" ? undefined : severity,
          zone_id: zoneId || undefined,
        });
        if (active) {
          setAlerts(res.items);
          setTotal(res.total);
          setLoading(false);
        }
      } catch (err: unknown) {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to fetch alerts list");
          setLoading(false);
        }
      }
    })();
    return () => {
      active = false;
    };
  }, [page, search, severity, zoneId]);


  const handleAcknowledge = async (alertId: string) => {
    try {
      await updateAlertStatus(alertId, {
        status: "ACKNOWLEDGED",
        is_acknowledged: true,
      });
      showToast("success", "Alert acknowledged and broadcast to field units.");
      fetchAlerts(true);
    } catch {
      showToast("error", "Failed to acknowledge alert");
    }
  };

  const handleResolve = async (alertId: string) => {
    try {
      await updateAlertStatus(alertId, {
        status: "RESOLVED",
      });
      showToast("success", "Alert resolved.");
      fetchAlerts(true);
    } catch {
      showToast("error", "Failed to resolve alert");
    }
  };


  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-rose-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-pulse" />
            Sensor & Perimeter Warnings
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Security Alerts Feed
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Real-time proximity warnings, buffer violations, and geofence alerts
          </p>
        </div>

        <div className="flex items-center gap-3">
          <PillNav
            value={severity}
            onChange={(val) => {
              setSeverity(val);
              setPage(1);
            }}
            options={[
              { id: "ALL", label: "All" },
              { id: "CRITICAL", label: "Critical" },
              { id: "WARNING", label: "Warning" },
              { id: "AWARENESS", label: "Awareness" },
            ]}
          />

          <button
            type="button"
            onClick={() => fetchAlerts(true)}
            disabled={refreshing}
            className="p-2 rounded-xl bg-slate-900 border border-slate-800 text-slate-300 hover:text-white transition-colors"
            title="Refresh alerts"
          >
            <RefreshCw
              className={`w-4 h-4 ${refreshing ? "animate-spin text-sky-400" : ""}`}
            />
          </button>
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800 flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search alert message, title, sector..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full bg-slate-800 border border-slate-700/80 text-white text-xs rounded-xl pl-9 pr-3 py-2 focus:outline-none focus:border-sky-400"
          />
        </div>

        <select
          value={zoneId}
          onChange={(e) => {
            setZoneId(e.target.value);
            setPage(1);
          }}
          className="bg-slate-800 border border-slate-700/80 text-slate-200 text-xs rounded-xl px-3 py-2 focus:outline-none focus:border-sky-400"
        >
          <option value="">All Sectors</option>
          {zones.map((z) => (
            <option key={z.id} value={z.id}>
              {z.name}
            </option>
          ))}
        </select>
      </div>

      {/* Alerts Feed */}
      <div className="space-y-3">
        {loading ? (
          <LoadingState label="Polling perimeter alerts feed..." />
        ) : error ? (
          <EmptyState
            title="Failed to Load Alerts"
            description={error}
            actionLabel="Retry"
            onAction={() => fetchAlerts()}
          />
        ) : alerts.length === 0 ? (
          <EmptyState
            title="No Active Perimeter Alerts"
            description="All monitored border sectors are currently within nominal safety limits."
          />
        ) : (
          alerts.map((item) => {
            const isCritical = item.severity === "CRITICAL";
            const isAcknowledged = Boolean(item.acknowledged_at);
            const isResolved = Boolean(item.resolved_at);
            const currentStatus = isResolved ? "RESOLVED" : isAcknowledged ? "ACKNOWLEDGED" : "ACTIVE";
            const zoneName = item.zone_id
              ? zones.find((z) => z.id === item.zone_id)?.name || `Sector ${item.zone_id}`
              : "Sector B";

            const CardContent = (
              <div
                className={`p-5 rounded-2xl bg-slate-900 border transition-all ${
                  isCritical && !isResolved
                    ? "border-rose-800/80 bg-slate-900/90 shadow-xl shadow-rose-950/20"
                    : isAcknowledged
                    ? "border-slate-800 bg-slate-900/60 opacity-80"
                    : "border-slate-800 bg-slate-900"
                }`}
              >
                <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
                  <div className="flex items-start gap-3.5">
                    <div
                      className={`p-2.5 rounded-xl shrink-0 ${
                        isCritical
                          ? "bg-rose-950/80 text-rose-400 border border-rose-800/80"
                          : item.severity === "WARNING"
                          ? "bg-amber-950/80 text-amber-400 border border-amber-800/80"
                          : "bg-sky-950/80 text-sky-400 border border-sky-800/80"
                      }`}
                    >
                      {isCritical ? (
                        <AlertCircle className="w-5 h-5 animate-pulse" />
                      ) : (
                        <AlertTriangle className="w-5 h-5" />
                      )}
                    </div>

                    <div className="space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <StatusBadge status={item.severity} />
                        <span className="font-mono text-[11px] text-slate-400">
                          {zoneName}
                        </span>
                        <StatusBadge status={currentStatus} showIcon={false} />
                      </div>

                      <h3 className="text-sm font-bold text-white tracking-tight">
                        {item.title}
                      </h3>

                      <p className="text-xs text-slate-300 max-w-2xl leading-relaxed">
                        {item.message}
                      </p>

                      <div className="flex items-center gap-3 pt-2 text-[10px] text-slate-400 font-mono">
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3 text-sky-400" />
                          {new Date(item.created_at).toLocaleString()}
                        </span>
                        {item.location_lat !== undefined && item.location_lng !== undefined && (
                          <span>
                            Fix: {item.location_lat.toFixed(5)}, {item.location_lng.toFixed(5)}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>


                  {/* Actions */}
                  <div className="flex sm:flex-col items-center sm:items-end gap-2 shrink-0">
                    {!isAcknowledged && !isResolved && (
                      <Button
                        variant="secondary"
                        size="sm"
                        icon={<Check className="w-3.5 h-3.5" />}
                        onClick={() => handleAcknowledge(item.id)}
                      >
                        Acknowledge
                      </Button>
                    )}

                    {!isResolved && (
                      <Button
                        variant={isCritical ? "danger" : "ghost"}
                        size="sm"
                        icon={<CheckCircle2 className="w-3.5 h-3.5" />}
                        onClick={() => handleResolve(item.id)}
                      >
                        Resolve
                      </Button>
                    )}
                  </div>
                </div>
              </div>
            );

            if (isCritical && !isResolved) {
              return (
                <ElectricBorder key={item.id} glowColor="critical">
                  {CardContent}
                </ElectricBorder>
              );
            }

            return <div key={item.id}>{CardContent}</div>;
          })
        )}

        {/* Pagination Footer */}
        <div className="p-4 rounded-2xl bg-slate-900 border border-slate-800 flex items-center justify-between text-xs text-slate-400">
          <span>
            Total Alerts: <strong className="text-white">{total}</strong>
          </span>

          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
              className="p-1.5 rounded-lg bg-slate-800 text-slate-300 hover:text-white disabled:opacity-40"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="text-[11px] font-mono">
              Page {page} of {totalPages}
            </span>
            <button
              type="button"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
              className="p-1.5 rounded-lg bg-slate-800 text-slate-300 hover:text-white disabled:opacity-40"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
