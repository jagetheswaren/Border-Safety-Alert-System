"use client";

import React, { useState } from "react";
import { usePathname } from "next/navigation";
import {
  Menu,
  Search,
  Bell,
  Wifi,
  Radio,
  Cpu,
  RefreshCw,
} from "lucide-react";
import { User } from "@/lib/types";
import { Tooltip } from "@/components/ui/Tooltip";

interface TopBarProps {
  user: User | null;
  onOpenMobileMenu: () => void;
  onOpenCommandPalette: () => void;
}

export const TopBar: React.FC<TopBarProps> = ({
  user,
  onOpenMobileMenu,
  onOpenCommandPalette,
}) => {
  const pathname = usePathname();
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  // Compute title from pathname
  const pageTitle = (() => {
    if (pathname === "/dashboard") return "Operations Overview";
    if (pathname.startsWith("/dashboard/map")) return "Live Operations Map";
    if (pathname.startsWith("/dashboard/incidents")) return "Incidents Management";
    if (pathname.startsWith("/dashboard/alerts")) return "Security Alerts Feed";
    if (pathname.startsWith("/dashboard/devices")) return "Field Units Telemetry";
    if (pathname.startsWith("/dashboard/zones")) return "Safety Zones & Geofencing";
    if (pathname.startsWith("/dashboard/events")) return "Activity Logs";
    if (pathname.startsWith("/dashboard/sync")) return "Data Synchronization";
    if (pathname.startsWith("/dashboard/health")) return "System Health Matrix";
    if (pathname.startsWith("/dashboard/settings")) return "System Settings";
    return "Operations Center";
  })();

  return (
    <header className="h-14 px-4 border-b border-slate-800 bg-slate-900/90 backdrop-blur-md flex items-center justify-between sticky top-0 z-30 select-none">
      {/* Left: Mobile Toggle + Title */}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={onOpenMobileMenu}
          className="md:hidden p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800"
          aria-label="Open navigation menu"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div>
          <h1 className="text-sm font-bold text-white tracking-tight">
            {pageTitle}
          </h1>
          <p className="text-[10px] text-slate-400 hidden sm:block">
            Border Safety & Alert System · Telemetry Active
          </p>
        </div>
      </div>

      {/* Center: Command Palette Trigger */}
      <button
        type="button"
        onClick={onOpenCommandPalette}
        className="hidden lg:flex items-center gap-2.5 px-3 py-1.5 rounded-xl bg-slate-800/80 hover:bg-slate-800 border border-slate-700/60 text-xs text-slate-400 hover:text-slate-200 transition-colors shadow-sm"
      >
        <Search className="w-3.5 h-3.5 text-sky-400" />
        <span className="text-[11px]">Command search...</span>
        <kbd className="px-1.5 py-0.5 rounded bg-slate-900 text-[10px] text-slate-400 border border-slate-700 font-mono">
          Ctrl K
        </kbd>
      </button>

      {/* Right: Live Status Rail & Alerts Bell */}
      <div className="flex items-center gap-3">
        {/* Status Rail (Desktop) */}
        <div className="hidden sm:flex items-center gap-3 px-3 py-1 rounded-xl bg-slate-950/70 border border-slate-800/80 text-[11px] text-slate-300">
          <Tooltip content="FastAPI Backend Online">
            <span className="flex items-center gap-1.5 cursor-default">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <Wifi className="w-3 h-3 text-emerald-400" />
              <span className="text-[10px] uppercase font-bold text-slate-400">Backend</span>
            </span>
          </Tooltip>

          <span className="text-slate-700">•</span>

          <Tooltip content="GPS Geodesic Engine Ready">
            <span className="flex items-center gap-1.5 cursor-default">
              <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
              <Radio className="w-3 h-3 text-sky-400" />
              <span className="text-[10px] uppercase font-bold text-slate-400">GPS</span>
            </span>
          </Tooltip>

          <span className="text-slate-700">•</span>

          <Tooltip content="Deterministic Geofence & Local AI Operational">
            <span className="flex items-center gap-1.5 cursor-default">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
              <Cpu className="w-3 h-3 text-emerald-400" />
              <span className="text-[10px] uppercase font-bold text-slate-400">AI</span>
            </span>
          </Tooltip>

          <span className="text-slate-700">•</span>

          <Tooltip content="Offline Sync Queue Synchronized">
            <span className="flex items-center gap-1.5 cursor-default">
              <RefreshCw className="w-3 h-3 text-sky-400" />
              <span className="text-[10px] uppercase font-bold text-slate-400">Sync</span>
            </span>
          </Tooltip>
        </div>

        {/* Search button on small screens */}
        <button
          type="button"
          onClick={onOpenCommandPalette}
          className="lg:hidden p-2 rounded-xl bg-slate-800 text-slate-300 hover:text-white"
          title="Search"
        >
          <Search className="w-4 h-4" />
        </button>

        {/* Notifications Bell */}
        <div className="relative">
          <button
            type="button"
            onClick={() => setNotificationsOpen(!notificationsOpen)}
            className="p-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700/60 relative"
            title="Notifications"
          >
            <Bell className="w-4 h-4" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-rose-500 animate-pulse" />
          </button>

          {/* Quick Notification Dropdown */}
          {notificationsOpen && (
            <div className="absolute right-0 mt-2 w-72 rounded-2xl bg-slate-900 border border-slate-800 shadow-2xl p-3 z-50 animate-in fade-in">
              <div className="flex items-center justify-between pb-2 border-b border-slate-800">
                <span className="text-xs font-semibold text-white">Notifications</span>
                <span className="text-[10px] text-sky-400 font-bold">1 ACTIVE</span>
              </div>
              <div className="py-2.5 space-y-2">
                <div className="p-2 rounded-xl bg-slate-800/70 border border-slate-700/50 text-xs">
                  <p className="font-semibold text-rose-300 text-[11px]">Border Sector Alert</p>
                  <p className="text-slate-400 text-[10px] mt-0.5">
                    Proximity awareness sensor triggered in Sector B-2.
                  </p>
                  <span className="text-[9px] text-slate-400 mt-1 block">2 mins ago</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* User Profile Chip */}
        <div className="flex items-center gap-2 pl-2 border-l border-slate-800">
          <div className="w-7 h-7 rounded-lg bg-sky-700 text-white font-bold text-xs flex items-center justify-center">
            {user?.email ? user.email[0].toUpperCase() : "U"}
          </div>
        </div>
      </div>
    </header>
  );
};

