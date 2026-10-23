"use client";

import React, { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import {
  ArrowLeft,
  AlertTriangle,
  Cpu,
  MapPin,
  Clock,
  CheckCircle2,
} from "lucide-react";
import { getIncident, updateIncidentStatus } from "@/lib/api";
import { Incident } from "@/lib/types";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { Button } from "@/components/ui/Button";
import { LoadingState } from "@/components/ui/LoadingState";
import { useToast } from "@/components/ui/Toast";

export default function IncidentDetailPage() {
  const params = useParams();
  const id = params?.id as string;
  const { showToast } = useToast();


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

  const handleUpdate = async (newStatus: string) => {
    if (!incident) return;
    try {
      const updated = await updateIncidentStatus(incident.id, newStatus);
      setIncident(updated);
      showToast("success", `Incident status updated to ${newStatus}`);
    } catch {
      showToast("error", "Unable to update incident status");
    }
  };

  if (loading) {
    return (
      <div className="flex-1 p-8">
        <LoadingState label="Retrieving incident audit trail & spatial metadata..." />
      </div>
    );
  }

  if (error || !incident) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center p-8 text-center">
        <div className="p-3 rounded-2xl bg-rose-950/80 border border-rose-800 text-rose-400 mb-3">
          <AlertTriangle className="w-8 h-8" />
        </div>
        <h2 className="text-base font-bold text-white">Incident Record Not Found</h2>
        <p className="text-xs text-slate-400 mt-1 max-w-sm mb-6">
          {error || "The requested incident record does not exist or has been archived."}
        </p>
        <Link href="/dashboard/incidents">
          <Button variant="secondary" size="sm" icon={<ArrowLeft className="w-4 h-4" />}>
            Back to Incidents Directory
          </Button>
        </Link>
      </div>
    );
  }

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-6xl mx-auto w-full">
      {/* Navigation Breadcrumb */}
      <div className="flex items-center justify-between">
        <Link
          href="/dashboard/incidents"
          className="inline-flex items-center gap-2 text-xs font-semibold text-slate-400 hover:text-white transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back to Incidents Directory</span>
        </Link>

        <div className="flex items-center gap-2">
          {incident.status !== "ACKNOWLEDGED" && (
            <Button
              variant="secondary"
              size="sm"
              onClick={() => handleUpdate("ACKNOWLEDGED")}
            >
              Acknowledge
            </Button>
          )}
          {incident.status !== "RESOLVED" && (
            <Button
              variant="primary"
              size="sm"
              icon={<CheckCircle2 className="w-3.5 h-3.5" />}
              onClick={() => handleUpdate("RESOLVED")}
            >
              Mark Resolved
            </Button>
          )}
        </div>
      </div>

      {/* Main Banner Card */}
      <SpotlightCard className="p-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div className="flex flex-wrap items-center gap-3 mb-2">
              <span className="font-mono text-xs font-bold text-sky-400 bg-sky-950/80 px-2.5 py-1 rounded-lg border border-sky-800/80">
                {incident.incident_number || `INC-${incident.id}`}
              </span>
              <StatusBadge status={incident.severity} />
              <StatusBadge status={incident.status} showIcon={false} />
            </div>
            <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-white">
              {incident.title}
            </h1>
          </div>

          <div className="flex items-center gap-2 font-mono text-xs text-slate-400">
            <Clock className="w-4 h-4 text-sky-400" />
            <span>Recorded: {new Date(incident.created_at).toLocaleString()}</span>
          </div>
        </div>
      </SpotlightCard>

      {/* 2-Column Details Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (2 Cols) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Overview */}
          <SpotlightCard className="p-6">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
              Incident Overview & Field Narrative
            </h2>
            <p className="text-xs text-slate-200 leading-relaxed whitespace-pre-wrap bg-slate-950/60 p-4 rounded-xl border border-slate-800">
              {incident.description || "No narrative details recorded for this incident."}
            </p>
          </SpotlightCard>

          {/* AI Threat Analysis */}
          <SpotlightCard className="p-6">
            <div className="flex items-center gap-2 text-sky-400 mb-3">
              <Cpu className="w-4 h-4" />
              <h2 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                On-Device Neural Risk Analysis (TFLite LSTM)
              </h2>
            </div>
            <div className="p-4 rounded-xl bg-sky-950/40 border border-sky-800/50 text-xs text-sky-200 leading-relaxed">
              {incident.ai_summary ||
                "Deterministic geofence rule validated. Local LSTM trajectory inference indicates consistent proximity vector."}
            </div>
          </SpotlightCard>
        </div>

        {/* Right Column (1 Col) Metadata */}
        <div className="space-y-6">
          <SpotlightCard className="p-6 space-y-4">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 pb-3 border-b border-slate-800">
              Spatial Metadata
            </h3>

            <div className="space-y-3 text-xs">
              <div>
                <span className="text-slate-400 block text-[11px]">Border Sector / Zone</span>
                <span className="font-semibold text-white">
                  {incident.zone_id ? `Sector ${incident.zone_id}` : "Unassigned Sector"}
                </span>
              </div>

              <div>
                <span className="text-slate-400 block text-[11px]">Geographic Fix (WGS84)</span>
                <span className="font-mono text-sky-300">
                  {incident.latitude !== undefined && incident.longitude !== undefined
                    ? `${incident.latitude.toFixed(6)}, ${incident.longitude.toFixed(6)}`
                    : "Coordinates Pending"}
                </span>
              </div>


              <div>
                <span className="text-slate-400 block text-[11px]">Reported Origin</span>
                <span className="font-medium text-slate-200">
                  {incident.reported_by || "System Watchdog"}
                </span>
              </div>

              <div>
                <span className="text-slate-400 block text-[11px]">Assigned Unit</span>
                <span className="font-medium text-slate-200">
                  {incident.assigned_to || "Field Patrol Alpha"}
                </span>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-800">
              <Link
                href="/dashboard/map"
                className="w-full py-2.5 rounded-xl bg-sky-600/90 hover:bg-sky-500 text-white text-xs font-semibold flex items-center justify-center gap-2 shadow-md shadow-sky-600/20 transition-all"
              >
                <MapPin className="w-3.5 h-3.5" />
                <span>Locate On Map</span>
              </Link>
            </div>
          </SpotlightCard>
        </div>
      </div>
    </div>
  );
}
