"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { getIncident } from "@/lib/api";
import { Incident } from "@/lib/types";
import { ArrowLeft, AlertTriangle, Cpu } from "lucide-react";

export default function IncidentDetailPage() {
  const params = useParams();
  const id = params?.id as string;

  const [incident, setIncident] = useState<Incident | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    let active = true;
    getIncident(id)
      .then((data) => {
        if (active) {
          setIncident(data);
          setLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (active) {
          setError(err instanceof Error ? err.message : "Failed to load incident details");
          setLoading(false);
        }
      });
    return () => {
      active = false;
    };
  }, [id]);

  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center bg-gray-950 text-gray-400 text-sm p-8">
        Loading incident details...
      </div>
    );
  }

  if (error || !incident) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center bg-gray-950 p-8 text-white">
        <AlertTriangle className="w-12 h-12 text-red-400 mb-3" />
        <h2 className="text-xl font-bold mb-1">Incident Not Found</h2>
        <p className="text-sm text-gray-400 mb-6">{error || "The requested incident record does not exist or has been removed."}</p>
        <Link
          href="/dashboard/incidents"
          className="inline-flex items-center text-xs bg-gray-800 hover:bg-gray-700 text-white px-4 py-2 rounded-lg transition-colors border border-gray-700"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Incidents Directory
        </Link>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-auto p-8 bg-gray-950 text-white">
      {/* Back button */}
      <div className="mb-6">
        <Link
          href="/dashboard/incidents"
          className="inline-flex items-center text-xs text-gray-400 hover:text-white transition-colors"
        >
          <ArrowLeft className="w-4 h-4 mr-1.5" />
          Back to Incidents Directory
        </Link>
      </div>

      {/* Header Banner */}
      <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 mb-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex items-center space-x-3 mb-2">
              <span className="font-mono text-xs font-semibold text-blue-400 bg-blue-500/10 px-2.5 py-1 rounded border border-blue-500/20">
                {incident.incident_number || incident.id}
              </span>
              <span className={`px-2.5 py-1 rounded text-xs font-semibold ${
                incident.severity === "CRITICAL" ? "bg-red-500/20 text-red-400 border border-red-500/30" :
                incident.severity === "HIGH" ? "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30" :
                "bg-blue-500/20 text-blue-400 border border-blue-500/30"
              }`}>
                {incident.severity} SEVERITY
              </span>
              <span className={`px-2.5 py-1 rounded text-xs font-medium ${
                incident.status === "OPEN" ? "bg-green-500/20 text-green-400" :
                incident.status === "IN_PROGRESS" ? "bg-blue-500/20 text-blue-400" :
                "bg-gray-800 text-gray-400"
              }`}>
                {incident.status}
              </span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white">{incident.title}</h1>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Details */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <h2 className="text-lg font-semibold text-white mb-3">Incident Overview & Summary</h2>
            <p className="text-gray-300 text-sm leading-relaxed whitespace-pre-wrap">
              {incident.description || "No description provided for this incident."}
            </p>
          </div>

          {/* AI Analysis Section */}
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6">
            <div className="flex items-center space-x-2 text-blue-400 mb-3">
              <Cpu className="w-5 h-5" />
              <h2 className="text-lg font-semibold text-white">Edge AI Threat Analysis</h2>
            </div>
            <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4 text-xs text-blue-200">
              {incident.ai_summary || "Automated AI spatial trajectory classification pending further sensor updates."}
            </div>
          </div>
        </div>

        {/* Sidebar Metadata */}
        <div className="space-y-6">
          <div className="bg-gray-900 border border-gray-800 rounded-xl p-6 space-y-4">
            <h2 className="text-base font-semibold text-white border-b border-gray-800 pb-3">Incident Metadata</h2>
            
            <div className="space-y-3 text-xs">
              <div>
                <span className="text-gray-500 block">Category</span>
                <span className="font-medium text-gray-200">{incident.category}</span>
              </div>

              <div>
                <span className="text-gray-500 block">Target Zone</span>
                <span className="font-medium text-gray-200">{incident.zone_id || "Unassigned Sector"}</span>
              </div>

              <div>
                <span className="text-gray-500 block">Coordinates</span>
                <span className="font-mono text-gray-300">
                  {incident.latitude && incident.longitude
                    ? `${incident.latitude.toFixed(4)}, ${incident.longitude.toFixed(4)}`
                    : "N/A"}
                </span>
              </div>

              <div>
                <span className="text-gray-500 block">Reported By</span>
                <span className="font-medium text-gray-200">{incident.reported_by || "System Watchdog"}</span>
              </div>

              <div>
                <span className="text-gray-500 block">Assigned Unit</span>
                <span className="font-medium text-gray-200">{incident.assigned_to || "Unassigned"}</span>
              </div>

              <div>
                <span className="text-gray-500 block">Reported Time</span>
                <span className="font-medium text-gray-300">{new Date(incident.created_at).toLocaleString()}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
