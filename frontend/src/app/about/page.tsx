"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, Shield, Map, Cpu, Database, Layers, CheckCircle2 } from "lucide-react";
import { AnimatedContent } from "@/components/reactbits/animations/AnimatedContent";
import { ScrollReveal } from "@/components/reactbits/animations/ScrollReveal";
import { GridBackground } from "@/components/reactbits/backgrounds/GridBackground";
import { SpotlightCard } from "@/components/reactbits/cards/SpotlightCard";
import { DecryptedText } from "@/components/reactbits/text/DecryptedText";
import { BSASPrimaryButton } from "@/components/ui/BSASButtons";

export default function AboutPage() {
  return (
    <div className="relative min-h-screen bg-slate-950 text-slate-100 p-6 md:p-12 overflow-x-hidden">
      {/* Background Grid */}
      <GridBackground className="opacity-25" />

      <div className="relative z-10 max-w-5xl mx-auto space-y-12">
        {/* Header */}
        <AnimatedContent distance={12} duration={260}>
          <div className="border-b border-slate-800 pb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 text-xs font-mono text-sky-400 uppercase tracking-widest mb-1">
                <Link
                  href="/dashboard"
                  className="inline-flex items-center gap-1 hover:text-sky-300 transition-colors"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  Return to Operations
                </Link>
                <span>/</span>
                <span>SYSTEM ARCHITECTURE</span>
              </div>
              <h1 className="text-3xl font-bold tracking-tight text-white flex items-center gap-3">
                <Shield className="w-8 h-8 text-sky-400" />
                <DecryptedText text="BORDER SAFETY & ALERT SYSTEM" speed={30} />
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                Civilian-first geospatial situational awareness platform (Release v1.2.0-STABLE).
              </p>
            </div>

            <Link href="/dashboard/map">
              <BSASPrimaryButton size="md" icon={<Map className="w-4 h-4" />}>
                Launch Map Canvas
              </BSASPrimaryButton>
            </Link>
          </div>
        </AnimatedContent>

        {/* Core Pillars */}
        <ScrollReveal distance={16}>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <SpotlightCard className="p-6">
              <Map className="w-6 h-6 text-sky-400 mb-3" />
              <h3 className="text-base font-bold text-white mb-2">Dual Map Engine</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Seamless fusion of Google Maps Vector basemaps (Places, Routes, 360° Street View) with MapLibre GL JS offline rendering when disconnected.
              </p>
            </SpotlightCard>

            <SpotlightCard className="p-6">
              <Cpu className="w-6 h-6 text-emerald-400 mb-3" />
              <h3 className="text-base font-bold text-white mb-2">On-Device TFLite AI</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                LSTM neural network trajectory prediction running locally on mobile hardware with zero cloud dependency for critical safety alarms.
              </p>
            </SpotlightCard>

            <SpotlightCard className="p-6">
              <Database className="w-6 h-6 text-amber-400 mb-3" />
              <h3 className="text-base font-bold text-white mb-2">Deterministic Storage</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Local SQLite transaction ledger caches all sensor telemetry and safety violations, synchronizing idempotently once connection recovers.
              </p>
            </SpotlightCard>
          </div>
        </ScrollReveal>

        {/* Dataset Provenance & Attributions */}
        <ScrollReveal distance={16}>
          <div className="p-6 rounded-2xl bg-slate-900/70 border border-slate-800 space-y-4">
            <h2 className="text-base font-semibold text-white flex items-center gap-2">
              <Layers className="w-5 h-5 text-sky-400" />
              Dataset Provenance & Legal Disclaimers
            </h2>
            <div className="text-xs text-slate-300 leading-relaxed space-y-3">
              <p>
                <strong>Operational Awareness Invariant:</strong> BSAS is engineered as a civilian situational awareness and navigation safety assistance tool. Geofence demarcations and buffer lines represent operational safety corridors defined in local configuration files and do not purport to resolve complex international boundary disputes.
              </p>
              <p>
                <strong>Map Licensing:</strong> Online map imagery, Place search, route navigation, and Street View 360° panoramas are powered by Google Maps Platform APIs under licensed terms. Offline fallback tiles are rendered using open-source MapLibre GL and local vector GeoJSON assets.
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-3 border-t border-slate-800 text-xs">
              <div className="flex items-center gap-2 text-slate-400">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>Google Maps Platform API Compliance Verified</span>
              </div>
              <div className="flex items-center gap-2 text-slate-400">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
                <span>Turf.js WGS84 Geodesic Distance Calculation</span>
              </div>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </div>
  );
}
