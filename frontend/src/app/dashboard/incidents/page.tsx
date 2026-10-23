"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Eye,
  MapPin,
} from "lucide-react";
import { getIncidents, getZones, updateIncidentStatus } from "@/lib/api";
import { Incident, Zone, PaginatedResponse } from "@/lib/types";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { PillNav } from "@/components/reactbits/PillNav";
import { Drawer } from "@/components/ui/Drawer";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { LoadingState } from "@/components/ui/LoadingState";
import { useToast } from "@/components/ui/Toast";

export default function IncidentsListPage() {
  const { showToast } = useToast();
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [search, setSearch] = useState("");
  const [severity, setSeverity] = useState("");
  const [status, setStatus] = useState<string>("ALL");
  const [zoneId, setZoneId] = useState("");

  const [selectedIncident, setSelectedIncident] = useState<Incident | null>(null);
  const [loading, setLoading] = useState(true);
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

  const fetchIncidents = async () => {
    await Promise.resolve();
    setLoading(true);
    const skip = (page - 1) * pageSize;
    try {
      const res: PaginatedResponse<Incident> = await getIncidents({
        skip,
        limit: pageSize,
        search: search || undefined,
        severity: severity || undefined,
        status: status === "ALL" ? undefined : status,
        zone_id: zoneId || undefined,
      });
      setIncidents(res.items);
      setTotal(res.total);
      setLoading(false);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to fetch incidents list");
      setLoading(false);
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
        const res = await getIncidents({
          skip,
          limit: pageSize,
          search: search || undefined,
          severity: severity || undefined,
          status: status === "ALL" ? undefined : status,
          zone_id: zoneId || undefined,
        });
        if (active) {
          setIncidents(res.items);
          setTotal(res.total);
          setLoading(false);
        }
      } catch (err: unknown) {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to fetch incidents list");
          setLoading(false);
        }
      }
    })();
    return () => {
      active = false;
    };
  }, [page, search, severity, status, zoneId]);


  const handleStatusUpdate = async (incidentId: string, newStatus: string) => {
    try {
      await updateIncidentStatus(incidentId, newStatus);
      showToast("success", `Incident status updated to ${newStatus}`);
      fetchIncidents();
      if (selectedIncident && selectedIncident.id === incidentId) {
        setSelectedIncident({ ...selectedIncident, status: newStatus });
      }
    } catch {
      showToast("error", "Failed to update incident status");
    }
  };


  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-400" />
            Operational Records
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Incidents Directory
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Audit, verify, and acknowledge field security reports and perimeter incursions
          </p>
        </div>

        <div className="flex items-center gap-2">
          <PillNav
            value={status}
            onChange={(val) => {
              setStatus(val);
              setPage(1);
            }}
            options={[
              { id: "ALL", label: "All" },
              { id: "OPEN", label: "Open" },
              { id: "ACKNOWLEDGED", label: "Acknowledged" },
              { id: "RESOLVED", label: "Resolved" },
            ]}
          />
        </div>
      </div>

      {/* Filter Toolbar */}
      <div className="p-3.5 rounded-2xl bg-slate-900 border border-slate-800 flex flex-wrap items-center gap-3">
        {/* Search */}
        <div className="relative flex-1 min-w-[200px]">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search incident number, title, or details..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="w-full bg-slate-800 border border-slate-700/80 text-white text-xs rounded-xl pl-9 pr-3 py-2 focus:outline-none focus:border-sky-400"
          />
        </div>

        {/* Severity */}
        <select
          value={severity}
          onChange={(e) => {
            setSeverity(e.target.value);
            setPage(1);
          }}
          className="bg-slate-800 border border-slate-700/80 text-slate-200 text-xs rounded-xl px-3 py-2 focus:outline-none focus:border-sky-400"
        >
          <option value="">All Severities</option>
          <option value="CRITICAL">Critical</option>
          <option value="WARNING">Warning</option>
          <option value="AWARENESS">Awareness</option>
        </select>

        {/* Zone */}
        <select
          value={zoneId}
          onChange={(e) => {
            setZoneId(e.target.value);
            setPage(1);
          }}
          className="bg-slate-800 border border-slate-700/80 text-slate-200 text-xs rounded-xl px-3 py-2 focus:outline-none focus:border-sky-400"
        >
          <option value="">All Border Sectors</option>
          {zones.map((z) => (
            <option key={z.id} value={z.id}>
              {z.name}
            </option>
          ))}
        </select>
      </div>

      {/* Table / List */}
      <div className="rounded-2xl border border-slate-800 bg-slate-900 overflow-hidden shadow-2xl">
        {loading ? (
          <LoadingState label="Loading incident records..." />
        ) : error ? (
          <EmptyState
            title="Failed to Load Incidents"
            description={error}
            actionLabel="Retry"
            onAction={fetchIncidents}
          />
        ) : incidents.length === 0 ? (
          <EmptyState
            title="No Incidents Found"
            description="No incidents match the active search criteria or sector filters."
          />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/60 text-slate-400 font-semibold uppercase text-[10px] tracking-wider">
                  <th className="py-3 px-4">Ref / Number</th>
                  <th className="py-3 px-4">Title & Details</th>
                  <th className="py-3 px-4">Sector</th>
                  <th className="py-3 px-4">Severity</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4">Timestamp</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {incidents.map((item) => (
                  <tr
                    key={item.id}
                    onClick={() => setSelectedIncident(item)}
                    className="hover:bg-slate-800/50 cursor-pointer transition-colors group"
                  >
                    <td className="py-3.5 px-4 font-mono font-bold text-sky-400 whitespace-nowrap">
                      {item.incident_number || `INC-${item.id}`}
                    </td>
                    <td className="py-3.5 px-4 min-w-[200px]">
                      <p className="font-semibold text-white group-hover:text-sky-300 transition-colors">
                        {item.title}
                      </p>
                      <p className="text-[11px] text-slate-400 line-clamp-1 mt-0.5">
                        {item.description}
                      </p>
                    </td>
                    <td className="py-3.5 px-4 text-slate-300 whitespace-nowrap">
                      {zones.find((z) => z.id === item.zone_id)?.name || (item.zone_id ? `Sector ${item.zone_id}` : "Sector A")}
                    </td>

                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <StatusBadge status={item.severity} />
                    </td>
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <StatusBadge status={item.status} showIcon={false} />
                    </td>
                    <td className="py-3.5 px-4 text-slate-400 font-mono text-[11px] whitespace-nowrap">
                      {new Date(item.created_at).toLocaleDateString()}{" "}
                      {new Date(item.created_at).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </td>
                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      <Link
                        href={`/dashboard/incidents/${item.id}`}
                        onClick={(e) => e.stopPropagation()}
                        className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-sky-600 text-slate-300 hover:text-white transition-colors text-[11px]"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>Inspect</span>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Footer */}
        <div className="px-4 py-3 border-t border-slate-800 bg-slate-950/40 flex items-center justify-between text-xs text-slate-400">
          <span>
            Showing <strong className="text-white">{incidents.length}</strong> of{" "}
            <strong className="text-white">{total}</strong> records
          </span>

          <div className="flex items-center gap-2">
            <button
              type="button"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
              className="p-1.5 rounded-lg bg-slate-800 text-slate-300 hover:text-white disabled:opacity-40"
              title="Previous page"
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
              title="Next page"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Incident Quick Detail Drawer */}
      <Drawer
        isOpen={Boolean(selectedIncident)}
        onClose={() => setSelectedIncident(null)}
        title={selectedIncident?.incident_number || "Incident Detail"}
        subtitle={`Recorded on ${
          selectedIncident?.created_at
            ? new Date(selectedIncident.created_at).toLocaleString()
            : ""
        }`}
      >
        {selectedIncident && (
          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <StatusBadge status={selectedIncident.severity} />
              <StatusBadge status={selectedIncident.status} showIcon={false} />
            </div>

            <div>
              <h3 className="text-sm font-bold text-white">
                {selectedIncident.title}
              </h3>
              <p className="text-xs text-slate-300 mt-2 leading-relaxed bg-slate-950/60 p-3 rounded-xl border border-slate-800">
                {selectedIncident.description}
              </p>
            </div>

            {/* Coordinates Snapshot */}
            <div className="p-3 rounded-xl bg-slate-950/80 border border-slate-800 space-y-1.5 text-xs font-mono">
              <div className="flex items-center gap-2 text-sky-400 font-semibold">
                <MapPin className="w-3.5 h-3.5" />
                <span>Geographic Fix</span>
              </div>
              <p className="text-slate-300">
                {selectedIncident.latitude !== undefined && selectedIncident.longitude !== undefined
                  ? `Lat: ${selectedIncident.latitude.toFixed(6)}, Lng: ${selectedIncident.longitude.toFixed(6)}`
                  : "Coordinates Pending"}
              </p>
            </div>


            {/* Quick Action Controls */}
            <div className="space-y-2 pt-4 border-t border-slate-800">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                Status Transitions
              </p>
              <div className="flex gap-2">
                {selectedIncident.status !== "ACKNOWLEDGED" && (
                  <Button
                    variant="secondary"
                    size="sm"
                    className="flex-1"
                    onClick={() =>
                      handleStatusUpdate(selectedIncident.id, "ACKNOWLEDGED")
                    }
                  >
                    Acknowledge
                  </Button>
                )}
                {selectedIncident.status !== "RESOLVED" && (
                  <Button
                    variant="primary"
                    size="sm"
                    className="flex-1"
                    onClick={() =>
                      handleStatusUpdate(selectedIncident.id, "RESOLVED")
                    }
                  >
                    Resolve Incident
                  </Button>
                )}
              </div>

              <Link
                href={`/dashboard/incidents/${selectedIncident.id}`}
                className="w-full mt-2 block text-center py-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-xs font-medium text-white transition-colors"
              >
                Open Full Audit Page →
              </Link>
            </div>
          </div>
        )}
      </Drawer>
    </div>
  );
}
