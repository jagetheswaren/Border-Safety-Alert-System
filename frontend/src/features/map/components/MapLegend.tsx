"use client";

import React, { useState } from 'react';
import { Layers, ChevronDown, ChevronUp } from 'lucide-react';

export function MapLegend() {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <div className="absolute bottom-6 right-6 z-20 bg-gray-900/95 backdrop-blur-md border border-gray-800 text-white rounded-xl shadow-2xl p-3 text-xs w-64 select-none transition-all">
      <div
        className="flex items-center justify-between cursor-pointer font-semibold text-gray-200 pb-1"
        onClick={() => setCollapsed(!collapsed)}
      >
        <span className="flex items-center space-x-1.5">
          <Layers className="w-3.5 h-3.5 text-blue-400" />
          <span>Operational Legend</span>
        </span>
        <button
          className="text-gray-400 hover:text-white"
          aria-label={collapsed ? "Expand operational legend" : "Collapse operational legend"}
        >
          {collapsed ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
        </button>
      </div>

      {!collapsed && (
        <div className="mt-2.5 space-y-2 border-t border-gray-800/80 pt-2 text-[11px] text-gray-300">
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-blue-500 border border-blue-300 ring-2 ring-blue-500/20" />
            <span>Current Device Fix</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-red-600 border border-white" />
            <span>Active Incident</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-4 h-0.5 bg-red-500" />
            <span>Monitored Border Demarcation</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded bg-blue-500/30 border border-blue-500" />
            <span>Awareness Zone (2000m)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded bg-amber-500/30 border border-amber-500" />
            <span>Warning Buffer (1000m)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded bg-red-500/30 border border-red-500" />
            <span>Critical Exclusion Zone (300m)</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="w-4 h-1 bg-indigo-500 rounded-sm" />
            <span>Navigable Route Path</span>
          </div>
        </div>
      )}
    </div>
  );
}
