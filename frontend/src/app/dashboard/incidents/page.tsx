"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { getIncidents, getZones } from "@/lib/api";
import { Incident, Zone, PaginatedResponse } from "@/lib/types";
import { Search, ChevronLeft, ChevronRight, FileText, AlertTriangle, Eye } from "lucide-react";

export default function IncidentsListPage() {
  const [incidents, setIncidents] = useState<Incident[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [search, setSearch] = useState("");
  const [severity, setSeverity] = useState("");
  const [status, setStatus] = useState("");
  const [category, setCategory] = useState("");
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
    getIncidents({
      skip,
      limit: pageSize,
      search: search || undefined,
      severity: severity || undefined,
      status: status || undefined,
      category: category || undefined,
      zone_id: zoneId || undefined,
    })
      .then((res: PaginatedResponse<Incident>) => {
        if (active) {
          setIncidents(res.items);
          setTotal(res.total);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to fetch incidents list");
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, [page, search, severity, status, category, zoneId]);

  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="flex-1 overflow-auto p-8 bg-gray-950 text-white">
      <header className="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Incidents Directory</h1>
          <p className="text-gray-400 text-sm mt-1">Manage and audit border security incidents</p>
        </div>
      </header>

      {/* Filters & Search Toolbar */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 mb-6 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
          {/* Search */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-3 text-gray-500" />
            <input
              type="text"
              placeholder="Search title, ID..."
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

          {/* Status */}
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setPage(1);
            }}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Statuses</option>
            <option value="OPEN">Open</option>
            <option value="IN_PROGRESS">In Progress</option>
            <option value="RESOLVED">Resolved</option>
          </select>

          {/* Category */}
          <select
            value={category}
            onChange={(e) => {
              setCategory(e.target.value);
              setPage(1);
            }}
            className="bg-gray-800 border border-gray-700 text-white text-sm rounded-lg px-3 py-2 focus:outline-none focus:ring-1 focus:ring-blue-500"
          >
            <option value="">All Categories</option>
            <option value="SECURITY_BREACH">Security Breach</option>
            <option value="SUSPICIOUS_VEHICLE">Suspicious Vehicle</option>
            <option value="COMMUNICATION_LOSS">Communication Loss</option>
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

      {/* Incidents Table / List */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden shadow-xl">
        {loading ? (
          <div className="p-12 text-center text-gray-400">Loading incidents data...</div>
        ) : error ? (
          <div className="p-12 text-center text-red-400">
            <AlertTriangle className="w-8 h-8 mx-auto mb-2" />
            <p className="font-semibold text-sm">{error}</p>
          </div>
        ) : incidents.length === 0 ? (
          <div className="p-12 text-center text-gray-500">
            <FileText className="w-10 h-10 mx-auto mb-3 text-gray-700" />
            <p className="text-base font-medium text-gray-400">No incidents match the specified filters</p>
            <p className="text-xs text-gray-600 mt-1">Try resetting your search query or filter selection</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-gray-300">
              <thead className="bg-gray-800/60 text-xs uppercase tracking-wider text-gray-400 border-b border-gray-800">
                <tr>
                  <th className="px-6 py-3.5">Incident ID</th>
                  <th className="px-6 py-3.5">Title</th>
                  <th className="px-6 py-3.5">Category</th>
                  <th className="px-6 py-3.5">Severity</th>
                  <th className="px-6 py-3.5">Status</th>
                  <th className="px-6 py-3.5">Created</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {incidents.map((inc) => (
                  <tr key={inc.id} className="hover:bg-gray-800/40 transition-colors">
                    <td className="px-6 py-4 font-mono text-xs text-blue-400">
                      {inc.incident_number || inc.id.substring(0, 8)}
                    </td>
                    <td className="px-6 py-4 font-medium text-white">{inc.title}</td>
                    <td className="px-6 py-4 text-xs text-gray-400">{inc.category}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${
                        inc.severity === "CRITICAL" ? "bg-red-500/20 text-red-400 border border-red-500/30" :
                        inc.severity === "HIGH" ? "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30" :
                        "bg-blue-500/20 text-blue-400 border border-blue-500/30"
                      }`}>
                        {inc.severity}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                        inc.status === "OPEN" ? "bg-green-500/20 text-green-400" :
                        inc.status === "IN_PROGRESS" ? "bg-blue-500/20 text-blue-400" :
                        "bg-gray-700 text-gray-300"
                      }`}>
                        {inc.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-xs text-gray-400">
                      {new Date(inc.created_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <Link
                        href={`/dashboard/incidents/${inc.id}`}
                        className="inline-flex items-center text-xs font-medium text-blue-400 hover:text-blue-300"
                      >
                        <Eye className="w-3.5 h-3.5 mr-1" />
                        View
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Footer */}
        {!loading && !error && total > 0 && (
          <div className="px-6 py-3.5 border-t border-gray-800 flex items-center justify-between text-xs text-gray-400 bg-gray-900">
            <span>
              Showing {Math.min((page - 1) * pageSize + 1, total)} to {Math.min(page * pageSize, total)} of {total} incidents
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
