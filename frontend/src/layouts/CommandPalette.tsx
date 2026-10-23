"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Search,
  Map,
  FileText,
  Bell,
  Users,
  Layers,
  HeartPulse,
  Settings,
  RefreshCw,
  X,
} from "lucide-react";

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  onClose,
}) => {
  const router = useRouter();
  const [query, setQuery] = useState("");

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const commands = [
    { label: "Overview Dashboard", category: "Navigation", href: "/dashboard", icon: Search },
    { label: "Live Operations Map", category: "Navigation", href: "/dashboard/map", icon: Map },
    { label: "Incidents Directory", category: "Operations", href: "/dashboard/incidents", icon: FileText },
    { label: "Perimeter Alerts Feed", category: "Operations", href: "/dashboard/alerts", icon: Bell },
    { label: "Field Units & Telemetry", category: "Operations", href: "/dashboard/devices", icon: Users },
    { label: "Monitored Boundaries", category: "Intelligence", href: "/dashboard/boundaries", icon: Layers },
    { label: "Safety Zones & Geofencing", category: "Intelligence", href: "/dashboard/zones", icon: Layers },
    { label: "Operational Analytics", category: "Intelligence", href: "/dashboard/analytics", icon: Search },
    { label: "Offline Sync Center", category: "System", href: "/dashboard/sync", icon: RefreshCw },
    { label: "System Health Diagnostics", category: "System", href: "/dashboard/health", icon: HeartPulse },
    { label: "Settings & Preferences", category: "System", href: "/dashboard/settings", icon: Settings },
  ];

  const filtered = commands.filter((cmd) =>
    cmd.label.toLowerCase().includes(query.toLowerCase()) ||
    cmd.category.toLowerCase().includes(query.toLowerCase())
  );

  const handleSelect = (href: string) => {
    router.push(href);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 p-4" role="dialog" aria-modal="true">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />

      <div className="relative z-10 w-full max-w-lg bg-slate-900 border border-slate-700/80 rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Search Input */}
        <div className="flex items-center px-4 border-b border-slate-800 bg-slate-900/90">
          <Search className="w-4 h-4 text-sky-400 mr-3" />
          <input
            type="text"
            placeholder="Type a command or jump to page..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoFocus
            className="w-full bg-transparent py-3.5 text-xs text-white placeholder-slate-400 focus:outline-none"
          />
          <button
            type="button"
            onClick={onClose}
            className="p-1 rounded-md text-slate-400 hover:text-white"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Results */}
        <div className="max-h-72 overflow-y-auto p-2 space-y-1">
          {filtered.length === 0 ? (
            <p className="py-6 text-center text-xs text-slate-400">
              No matching operational command found.
            </p>
          ) : (
            filtered.map((cmd) => {
              const Icon = cmd.icon;
              return (
                <button
                  key={cmd.href}
                  type="button"
                  onClick={() => handleSelect(cmd.href)}
                  className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs text-left text-slate-300 hover:bg-slate-800 hover:text-white transition-colors group"
                >
                  <div className="flex items-center gap-3">
                    <div className="p-1.5 rounded-lg bg-slate-800 group-hover:bg-sky-600/30 text-slate-400 group-hover:text-sky-400 transition-colors">
                      <Icon className="w-3.5 h-3.5" />
                    </div>
                    <span>{cmd.label}</span>
                  </div>
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider">
                    {cmd.category}
                  </span>
                </button>
              );
            })
          )}
        </div>

        {/* Footer shortcuts */}
        <div className="px-4 py-2 border-t border-slate-800 bg-slate-950/60 text-[10px] text-slate-400 flex justify-between">
          <span>Navigation Shortcuts</span>
          <span>Esc to exit</span>
        </div>
      </div>
    </div>
  );
};
