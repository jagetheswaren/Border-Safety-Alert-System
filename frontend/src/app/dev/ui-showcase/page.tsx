"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  Compass,
  Crosshair,
  Shield,
  Layers,
  MapPin,
  Bell,
  ArrowLeft,
} from "lucide-react";
import {
  BSASPrimaryButton,
  BSASSecondaryButton,
  BSASGhostButton,
  BSASDangerButton,
  BSASIconButton,
  BSASSlideButton,
  BSASMagneticButton,
} from "@/components/ui/BSASButtons";
import {
  SpotlightCard,
  ElectricBorder,
  GlassSurface,
  Dock,
  DockItem,
  PillNav,
  DecryptedText,
  ShinyText,
  CountUp,
  AnimatedContent,
  ScrollReveal,
  AnimatedList,
  GridBackground,
} from "@/components/reactbits";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { LoadingState } from "@/components/ui/LoadingState";
import { EmptyState } from "@/components/ui/EmptyState";

/**
 * BSAS React Bits Development Showcase
 * Interactive visual QA environment for all tactical design tokens and motion components.
 */
export default function UIShowcasePage() {
  const [activeFilter, setActiveFilter] = useState<"ALL" | "CRITICAL" | "WARNING" | "SAFE">("ALL");
  const [slideState, setSlideState] = useState<"idle" | "loading" | "success">("idle");
  const [dockSelected, setDockSelected] = useState<string>("locate");

  const handleSlideClick = () => {
    setSlideState("loading");
    setTimeout(() => {
      setSlideState("success");
      setTimeout(() => setSlideState("idle"), 2000);
    }, 1200);
  };

  return (
    <div className="relative min-h-screen bg-slate-950 text-slate-100 p-6 md:p-12 overflow-x-hidden">
      {/* Background Grid Pattern */}
      <GridBackground className="opacity-30" />

      <div className="relative z-10 max-w-7xl mx-auto space-y-12">
        {/* Navigation & Header */}
        <AnimatedContent distance={12} duration={260}>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-6">
            <div>
              <div className="flex items-center gap-2 text-xs font-mono text-sky-400 uppercase tracking-widest mb-1">
                <Link
                  href="/dashboard"
                  className="inline-flex items-center gap-1 hover:text-sky-300 transition-colors"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  Dashboard
                </Link>
                <span>/</span>
                <span>Dev Showcase</span>
              </div>
              <h1 className="text-2xl md:text-3xl font-bold tracking-tight text-white flex items-center gap-3">
                <DecryptedText text="BSAS COMPONENT MATRIX" speed={30} />
                <span className="text-xs px-2 py-0.5 rounded bg-sky-500/20 text-sky-400 border border-sky-500/30 font-mono">
                  REACT BITS
                </span>
              </h1>
              <p className="text-sm text-slate-400 mt-1">
                Visual inspection and interaction testing for all BSAS-adapted motion components.
              </p>
            </div>
            <div className="flex items-center gap-2">
              <ShinyText className="text-xs font-mono text-slate-400 font-semibold">
                BUILD STATUS: PASSING
              </ShinyText>
            </div>
          </div>
        </AnimatedContent>

        {/* Section 1: Button System (Section 31) */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-sky-400" />
                1. Unified Button System (Section 31)
              </h2>
              <span className="text-xs font-mono text-slate-500">7 TACTICAL VARIANTS</span>
            </div>

            <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 flex flex-wrap items-center gap-4">
              <BSASPrimaryButton icon={<Shield className="w-4 h-4" />}>
                BSASPrimaryButton
              </BSASPrimaryButton>

              <BSASSecondaryButton icon={<Layers className="w-4 h-4" />}>
                BSASSecondaryButton
              </BSASSecondaryButton>

              <BSASGhostButton>BSASGhostButton</BSASGhostButton>

              <BSASDangerButton>BSASDangerButton</BSASDangerButton>

              <BSASIconButton
                title="Quick Locate"
                aria-label="Quick Locate"
                icon={<Crosshair className="w-4 h-4 text-sky-400" />}
              />

              <BSASMagneticButton strength={14}>
                BSASMagneticButton
              </BSASMagneticButton>

              <BSASSlideButton
                label="SLIDE ACTION"
                loadingLabel="AUTHENTICATING..."
                successLabel="CONFIRMED ✓"
                state={slideState}
                onClick={handleSlideClick}
              />
            </div>
          </div>
        </ScrollReveal>

        {/* Section 2: Cards & Surfaces */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-cyan-400" />
              2. Tactical Cards & Glass Surfaces
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Spotlight Card */}
              <SpotlightCard className="p-6">
                <div className="text-xs font-mono text-sky-400 uppercase tracking-wider mb-2">
                  SpotlightCard
                </div>
                <h3 className="text-lg font-semibold text-white mb-1">Cursor-Tracking Glow</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Subtle mouse-following radial illumination for operational metric displays without layout reflow.
                </p>
                <div className="mt-4 text-2xl font-bold font-mono text-sky-300">
                  <CountUp to={1284} /> <span className="text-xs font-sans text-slate-400">km monitored</span>
                </div>
              </SpotlightCard>

              {/* Electric Border (Critical) */}
              <ElectricBorder glowColor="critical">
                <div className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-mono text-rose-400 uppercase tracking-wider">
                      ElectricBorder
                    </span>
                    <StatusBadge status="CRITICAL" />
                  </div>
                  <h3 className="text-lg font-semibold text-white mb-1">Active High-Priority Alert</h3>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    Reserved exclusively for active critical alerts and urgent operational incidents.
                  </p>
                  <div className="mt-4 font-mono text-xs text-rose-300">
                    STATUS: BOUNDARY PROXIMITY &lt; 300M
                  </div>
                </div>
              </ElectricBorder>

              {/* Glass Surface */}
              <GlassSurface blurLevel="md" className="p-6">
                <div className="text-xs font-mono text-slate-400 uppercase tracking-wider mb-2">
                  GlassSurface
                </div>
                <h3 className="text-lg font-semibold text-white mb-1">Tactical Map Glass</h3>
                <p className="text-xs text-slate-400 leading-relaxed">
                  High-contrast WCAG-compliant dark frosted glass for floating map controls and route planners.
                </p>
                <div className="mt-4 flex gap-2">
                  <StatusBadge status="ONLINE" />
                  <StatusBadge status="SAFE" />
                </div>
              </GlassSurface>
            </div>
          </div>
        </ScrollReveal>

        {/* Section 3: Navigation Components (Dock & PillNav) */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400" />
              3. Navigation & Control Systems
            </h2>

            <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800 space-y-6">
              {/* PillNav */}
              <div>
                <div className="text-xs font-mono text-slate-400 mb-2">
                  PILLNAV FILTER BAR (Sliding Indicator)
                </div>
                <PillNav
                  options={[
                    { id: "ALL", label: "All Telemetry", badge: 4 },
                    { id: "CRITICAL", label: "Critical", badge: 1 },
                    { id: "WARNING", label: "Warning", badge: 2 },
                    { id: "SAFE", label: "Safe", badge: 1 },
                  ]}
                  value={activeFilter}
                  onChange={(val) => setActiveFilter(val as typeof activeFilter)}
                />
              </div>

              {/* Dock */}
              <div>
                <div className="text-xs font-mono text-slate-400 mb-2">
                  TACTICAL MAP DOCK (Magnification & Tooltips)
                </div>
                <Dock direction="horizontal" className="inline-flex">
                  <DockItem
                    title="Locate Me"
                    active={dockSelected === "locate"}
                    onClick={() => setDockSelected("locate")}
                  >
                    <Crosshair className="w-4 h-4" />
                  </DockItem>
                  <DockItem
                    title="A-to-B Route"
                    active={dockSelected === "route"}
                    onClick={() => setDockSelected("route")}
                  >
                    <Compass className="w-4 h-4" />
                  </DockItem>
                  <DockItem
                    title="Street View 360°"
                    active={dockSelected === "streetview"}
                    onClick={() => setDockSelected("streetview")}
                  >
                    <MapPin className="w-4 h-4" />
                  </DockItem>
                  <DockItem
                    title="Layer Overlays"
                    active={dockSelected === "layers"}
                    onClick={() => setDockSelected("layers")}
                  >
                    <Layers className="w-4 h-4" />
                  </DockItem>
                  <DockItem
                    title="Notifications"
                    active={dockSelected === "alerts"}
                    onClick={() => setDockSelected("alerts")}
                  >
                    <Bell className="w-4 h-4" />
                  </DockItem>
                </Dock>
              </div>
            </div>
          </div>
        </ScrollReveal>

        {/* Section 4: Text Animations & Telemetry Rollers */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-amber-400" />
              4. Text Effects & Rolling Counters
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                <div className="text-xs font-mono text-slate-400 mb-2">DECRYPTEDTEXT</div>
                <div className="text-xl font-bold font-mono text-sky-400">
                  <DecryptedText text="SYS.AUTH_VERIFIED" speed={45} />
                </div>
                <p className="text-xs text-slate-500 mt-2">
                  Cyber-scramble character resolution on initial mount.
                </p>
              </div>

              <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                <div className="text-xs font-mono text-slate-400 mb-2">SHINYTEXT</div>
                <div className="text-xl font-bold">
                  <ShinyText className="text-white">OPERATIONAL READY</ShinyText>
                </div>
                <p className="text-xs text-slate-500 mt-2">
                  Luminous light streak passing across header text.
                </p>
              </div>

              <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                <div className="text-xs font-mono text-slate-400 mb-2">COUNTUP NUMERIC</div>
                <div className="text-3xl font-bold font-mono text-emerald-400">
                  <CountUp to={24980} /> <span className="text-xs font-sans text-slate-400">m geodesic</span>
                </div>
                <p className="text-xs text-slate-500 mt-2">
                  Rolling digit animation for telemetry metrics.
                </p>
              </div>
            </div>
          </div>
        </ScrollReveal>

        {/* Section 5: Animated List (Staggered Feed) */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-purple-400" />
              5. Staggered Animated List
            </h2>

            <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
              <AnimatedList staggerMs={40}>
                {[
                  { id: "EVT-101", title: "Device unit BSAS-ALPHA reported valid GNSS fix", time: "Just now", status: "SAFE" as const },
                  { id: "EVT-102", title: "Geofence proximity warning calculated: 850m to border", time: "2m ago", status: "WARNING" as const },
                  { id: "EVT-103", title: "Critical buffer threshold crossed in Sector 04", time: "5m ago", status: "CRITICAL" as const },
                  { id: "EVT-104", title: "Offline event synchronization confirmed with server", time: "12m ago", status: "ONLINE" as const },
                ].map((item) => (
                  <div
                    key={item.id}
                    className="flex items-center justify-between p-3.5 mb-2 rounded-xl bg-slate-900/80 border border-slate-800/80 hover:border-slate-700 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <span className="font-mono text-xs font-semibold text-sky-400">{item.id}</span>
                      <span className="text-xs text-slate-300">{item.title}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-[11px] text-slate-500">{item.time}</span>
                      <StatusBadge status={item.status} />
                    </div>
                  </div>
                ))}
              </AnimatedList>
            </div>
          </div>
        </ScrollReveal>

        {/* Section 6: UI Skeletons & Statuses */}
        <ScrollReveal distance={16}>
          <div className="space-y-4">
            <h2 className="text-base font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-slate-400" />
              6. Operational States & Feedback
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                <div className="text-xs font-mono text-slate-400 mb-3">LOADING STATE</div>
                <LoadingState label="Synchronizing telemetry with satellite array..." />
              </div>

              <div className="p-6 rounded-2xl bg-slate-900/60 border border-slate-800">
                <div className="text-xs font-mono text-slate-400 mb-3">EMPTY STATE</div>
                <EmptyState
                  title="No Pending Alerts"
                  description="All monitored sectors currently report normal situational parameters."
                  actionLabel="Refresh Sensor Array"
                  onAction={() => {}}
                />
              </div>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </div>
  );
}
