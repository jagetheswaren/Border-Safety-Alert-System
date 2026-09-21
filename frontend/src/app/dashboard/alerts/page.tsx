"use client";

import { useEffect, useState } from "react";
import { getAlerts, getZones } from "@/lib/api";
import { Alert, Zone, PaginatedResponse } from "@/lib/types";
import { Search, ChevronLeft, ChevronRight, AlertTriangle, MapPin, Bell } from "lucide-react";

export default function AlertsListPage() {
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [search, setSearch] = useState("");
  const [severity, setSeverity] = useState("");
  const [type, setType] = useState("");
  const [zoneId, setZoneId] = useState("");

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

  useEffect(() => {
    let active = true;
    const skip = (page - 1) * pageSize;
    getAlerts({
      skip,
      limit: pageSize,
      search: search || undefined,
      severity: severity || undefined,
      type: type || undefined,
      zone_id: zoneId || undefined,
    })
      .then((res: PaginatedResponse<Alert>) => {
        if (active) {
          setAlerts(res.items);
          setTotal(res.total);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to fetch alerts list");
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, [page, search, severity, type, zoneId]);

  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="flex-1 overflow-auto p-8 bg-gray-950 text-white">
      <header className="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Security Alerts Feed</h1>
          <p className="text-gray-400 text-sm mt-1">Real-time perimeter alerts and sensor warnings</p>
        </div>
      </header>

      {/* Toolbar Filters */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 mb-6 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
          {/* Search */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-3 text-gray-500" />
            <input
              type="text"
              placeholder="Search alert title, message..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="w-full bg-gray-800 border border-gray-700 text-white text-sm rounded-lg pl-9 pr-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>

          {/* Severity */}
          <select
            value={severity}
            onChange={(e) => {
              setSeverity(e.target.value);
              setPage(1);
            }}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Severities</option>
            <option value="CRITICAL">Critical</option>
            <option value="HIGH">High</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
          </select>

          {/* Type */}
          <select
            value={type}
            onChange={(e) => {
              setType(e.target.value);
              setPage(1);
            }}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Alert Types</option>
            <option value="GEOFENCE_BREACH">Geofence Breach</option>
            <option value="SPEED_WARNING">Speed Warning</option>
            <option value="PROXIMITY_ALERT">Proximity Alert</option>
          </select>

          {/* Zone */}
          <select
            value={zoneId}
            onChange={(e) => {
              setZoneId(e.target.value);
              setPage(1);
            }}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Zones</option>
            {zones.map((z) => (
              <option key={z.id} value={z.id}>
                {z.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Alerts Feed List */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-12 text-center text-gray-400">Loading alerts data...</div>
        ) : error ? (
          <div className="p-12 text-center text-red-400">
            <AlertTriangle className="w-8 h-8 mx-auto mb-2" />
            <p className="font-semibold text-sm">{error}</p>
          </div>
        ) : alerts.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <Bell className="w-10 h-10 mx-auto mb-3 text-gray-700" />
            <p className="text-base font-medium text-gray-400">No security alerts match the specified filters</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-800">
            {alerts.map((alt) => (
              <div key={alt.id} className="p-6 hover:bg-gray-800/40 transition-colors flex items-start space-x-4">
                <div className={`mt-1 rounded-lg p-2.5 ${
                  alt.severity === "CRITICAL" ? "bg-red-500/20 text-red-400 border border-red-500/30" :
                  alt.severity === "HIGH" ? "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30" :
                  "bg-blue-500/20 text-blue-400 border border-blue-500/30"
                }`}>
                  <AlertTriangle className="w-5 h-5" />
                </div>

                <div className="flex-1">
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-1 mb-1">
                    <h3 className="text-base font-semibold text-white">{alt.title}</h3>
                    <span className="text-xs text-gray-500">{new Date(alt.created_at).toLocaleString()}</span>
                  </div>
                  <p className="text-sm text-gray-300 mb-3">{alt.message}</p>
                  
                  <div className="flex flex-wrap items-center gap-3 text-xs">
                    <span className={`px-2 py-0.5 rounded font-semibold ${
                      alt.severity === "CRITICAL" ? "bg-red-500/20 text-red-400" :
                      alt.severity === "HIGH" ? "bg-yellow-500/20 text-yellow-400" :
                      "bg-blue-500/20 text-blue-400"
                    }`}>
                      {alt.severity}
                    </span>
                    <span className="bg-gray-800 text-gray-400 px-2 py-0.5 rounded uppercase font-mono">
                      {alt.type}
                    </span>
                    {alt.location_lat && alt.location_lng && (
                      <span className="flex items-center text-gray-400">
                        <MapPin className="w-3.5 h-3.5 mr-1 text-gray-500" />
                        {alt.location_lat.toFixed(4)}, {alt.location_lng.toFixed(4)}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Pagination Footer */}
        {!loading && !error && total > 0 && (
          <div className="px-6 py-3.5 border-t border-gray-800 flex items-center justify-between text-xs text-gray-400 bg-gray-900">
            <span>
              Showing {Math.min((page - 1) * pageSize + 1, total)} to {Math.min(page * pageSize, total)} of {total} alerts
            </span>
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="p-1.5 rounded-lg border border-gray-800 bg-gray-800/60 hover:bg-gray-800 disabled:opacity-40"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span>Page {page} of {totalPages}</span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="p-1.5 rounded-lg border border-gray-800 bg-gray-800/60 hover:bg-gray-800 disabled:opacity-40"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
