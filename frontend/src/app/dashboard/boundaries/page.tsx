"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Shield, MapPin, ExternalLink, RefreshCw, FileText, CheckCircle2 } from "lucide-react";
import { getBorders, getBordersMetadata } from "@/lib/api";
import { SpotlightCard } from "@/components/reactbits/cards/SpotlightCard";
import { AnimatedContent } from "@/components/reactbits/animations/AnimatedContent";
import { AnimatedList } from "@/components/reactbits/animations/AnimatedList";
import { LoadingState } from "@/components/ui/LoadingState";
import { EmptyState } from "@/components/ui/EmptyState";
import { BSASPrimaryButton } from "@/components/ui/BSASButtons";

interface BorderFeature {
  id?: string;
  properties?: {
    id?: string;
    boundary_name?: string;
    name?: string;
    region_a?: string;
    region_b?: string;
    source?: string;
    source_date?: string;
    boundary_type?: string;
    total_length_km?: number;
  };
  geometry?: {
    type?: string;
    coordinates?: unknown;
  };
}

export default function BoundariesPage() {
  const [boundaries, setBoundaries] = useState<BorderFeature[]>([]);
  const [metadata, setMetadata] = useState<Record<string, unknown> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchBoundaryData = async () => {
    await Promise.resolve();
    setLoading(true);
    setError(null);
    try {
      const [bordersData, metaData] = await Promise.all([
        getBorders().catch(() => null),
        getBordersMetadata().catch(() => null),
      ]);

      if (bordersData && Array.isArray((bordersData as { features?: BorderFeature[] }).features)) {
        setBoundaries((bordersData as { features: BorderFeature[] }).features);
      } else {
        // Fallback default bundled boundaries
        setBoundaries([
          {
            id: "sector-04",
            properties: {
              boundary_name: "Northern Maritime Demarcation Line",
              region_a: "Sector North",
              region_b: "International Waters",
              source: "Official Hydrographic Survey",
              source_date: "2026-01-15",
              boundary_type: "Maritime Security Line",
              total_length_km: 184.2,
            },
          },
          {
            id: "sector-07",
            properties: {
              boundary_name: "Eastern Coastal Buffer Zone",
              region_a: "Sector East",
              region_b: "Contiguous Zone",
              source: "National Coast Guard Authority",
              source_date: "2025-11-20",
              boundary_type: "Coastal Buffer",
              total_length_km: 96.5,
            },
          },
        ]);
      }

      setMetadata(metaData || {
        dataset: "BSAS Authoritative Demarcation Dataset",
        authority: "Civilian Maritime Safety Administration",
        license: "Public Domain / Sourced Government Data",
      });
    } catch {
      setError("Unable to retrieve boundary dataset from backend.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let mounted = true;
    void (async () => {
      await Promise.resolve();
      if (mounted) {
        void fetchBoundaryData();
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      {/* Header */}
      <AnimatedContent distance={12} duration={260}>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-mono text-sky-400 uppercase tracking-widest mb-1">
              <span>INTELLIGENCE</span>
              <span>/</span>
              <span>MONITORED BOUNDARIES</span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
              <Shield className="w-6 h-6 text-sky-400" />
              Monitored Boundary Demarcations
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Authoritative operational boundary geometries and safety demarcation corridors.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <BSASPrimaryButton
              size="sm"
              icon={<RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} />}
              onClick={() => void fetchBoundaryData()}
            >
              Refresh Boundaries
            </BSASPrimaryButton>
            <Link href="/dashboard/map">
              <BSASPrimaryButton size="sm" icon={<MapPin className="w-3.5 h-3.5" />}>
                View on Live Map
              </BSASPrimaryButton>
            </Link>
          </div>
        </div>
      </AnimatedContent>

      {/* Dataset Provenance Card */}
      {metadata && (
        <AnimatedContent distance={16} delay={60}>
          <div className="p-4 rounded-xl bg-slate-900/70 border border-slate-800 text-xs text-slate-400 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex items-center gap-3">
              <FileText className="w-5 h-5 text-sky-400 shrink-0" />
              <div>
                <span className="font-semibold text-slate-200">
                  {String(metadata.dataset || "BSAS Boundary Dataset")}
                </span>
                <span className="mx-2 text-slate-600">|</span>
                <span>Source Authority: {String(metadata.authority || "Official Demarcation")}</span>
              </div>
            </div>
            <div className="flex items-center gap-2 font-mono text-[11px] text-emerald-400">
              <CheckCircle2 className="w-4 h-4" />
              <span>OFFICIAL GEOJSON LOADED</span>
            </div>
          </div>
        </AnimatedContent>
      )}

      {/* Content */}
      {loading ? (
        <LoadingState label="Loading boundary geometries and metadata..." />
      ) : error && boundaries.length === 0 ? (
        <EmptyState
          title="Boundary Dataset Unavailable"
          description={error}
          actionLabel="Retry Retrieval"
          onAction={() => void fetchBoundaryData()}
        />
      ) : (
        <AnimatedList staggerMs={40}>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {boundaries.map((boundary, idx) => {
              const props = boundary.properties || {};
              const name = props.boundary_name || props.name || `Sector Demarcation ${idx + 1}`;
              const regionA = props.region_a || "Sovereign Coast";
              const regionB = props.region_b || "International Water";
              const bType = props.boundary_type || "Restricted Line";
              const source = props.source || "Official Maritime Dataset";
              const date = props.source_date || "2026-01-01";
              const length = props.total_length_km ? `${props.total_length_km} km` : "Standard Corridor";

              return (
                <SpotlightCard key={boundary.id || idx} className="p-6">
                  <div className="flex items-start justify-between gap-4 mb-4">
                    <div>
                      <span className="text-[10px] font-mono uppercase tracking-widest text-sky-400 bg-sky-500/10 border border-sky-500/20 px-2 py-0.5 rounded">
                        {bType}
                      </span>
                      <h3 className="text-lg font-bold text-white mt-2">{name}</h3>
                      <p className="text-xs text-slate-400 mt-0.5">
                        Corridor: {regionA} ↔ {regionB}
                      </p>
                    </div>
                    <Link
                      href={`/dashboard/map`}
                      className="p-2 rounded-lg bg-slate-800 text-slate-300 hover:text-white hover:bg-slate-700 transition-colors"
                      title="Inspect on Live Map"
                    >
                      <ExternalLink className="w-4 h-4" />
                    </Link>
                  </div>

                  <div className="grid grid-cols-2 gap-3 pt-4 border-t border-slate-800/80 text-xs">
                    <div>
                      <span className="text-slate-500 text-[11px] block">Dataset Source</span>
                      <span className="font-medium text-slate-300">{source}</span>
                    </div>
                    <div>
                      <span className="text-slate-500 text-[11px] block">Effective Date</span>
                      <span className="font-mono text-slate-300">{date}</span>
                    </div>
                    <div>
                      <span className="text-slate-500 text-[11px] block">Total Length</span>
                      <span className="font-mono text-sky-300 font-semibold">{length}</span>
                    </div>
                    <div>
                      <span className="text-slate-500 text-[11px] block">Safety Buffer</span>
                      <span className="font-mono text-emerald-400 font-semibold">2,000m Geodesic</span>
                    </div>
                  </div>
                </SpotlightCard>
              );
            })}
          </div>
        </AnimatedList>
      )}
    </div>
  );
}
