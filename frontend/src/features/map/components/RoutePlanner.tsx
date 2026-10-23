"use client";

import React from 'react';
import { RouteInfo } from '../types/map.types';
import { ArrowUpDown, X, Navigation2, Clock, Route as RouteIcon, Loader2 } from 'lucide-react';

interface RoutePlannerProps {
  routeInfo: RouteInfo | null;
  originName: string;
  destinationName: string;
  isLoading: boolean;
  error: string | null;
  onSwap: () => void;
  onClear: () => void;
  onUseCurrentLocationAsOrigin?: () => void;
  isOpen: boolean;
  onClose: () => void;
}

export function RoutePlanner({
  routeInfo,
  originName,
  destinationName,
  isLoading,
  error,
  onSwap,
  onClear,
  onUseCurrentLocationAsOrigin,
  isOpen,
  onClose,
}: RoutePlannerProps) {
  if (!isOpen) return null;

  return (
    <div className="absolute top-20 left-6 z-30 w-84 bg-gray-900/95 backdrop-blur-md border border-gray-800 text-white rounded-xl shadow-2xl p-4 text-xs select-none transition-all animate-in fade-in slide-in-from-left-4">
      <div className="flex items-center justify-between pb-2.5 border-b border-gray-800">
        <div className="flex items-center space-x-1.5 font-bold text-white text-sm">
          <RouteIcon className="w-4 h-4 text-indigo-400" />
          <span>Navigational Route Planner</span>
        </div>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-white p-1 rounded hover:bg-gray-800"
          aria-label="Close route planner"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      <div className="mt-3 space-y-2">
        {/* Origin A */}
        <div className="flex items-center space-x-2 bg-gray-950 p-2 rounded-lg border border-gray-800">
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 shrink-0 ring-2 ring-emerald-500/20" />
          <div className="flex-1 truncate">
            <div className="text-[10px] text-gray-500 font-semibold uppercase">Origin (A)</div>
            <div className="text-xs text-gray-200 truncate">{originName || 'Select or drop map pin A'}</div>
          </div>
          {onUseCurrentLocationAsOrigin && (
            <button
              onClick={onUseCurrentLocationAsOrigin}
              title="Use current GPS fix as origin"
              className="px-1.5 py-1 text-[10px] bg-blue-600/20 text-blue-400 hover:bg-blue-600/30 rounded border border-blue-500/30 shrink-0"
            >
              My GPS
            </button>
          )}
        </div>

        {/* Swap button */}
        <div className="flex justify-center -my-1">
          <button
            onClick={onSwap}
            disabled={!originName || !destinationName}
            title="Swap Origin and Destination"
            className="p-1 rounded-full bg-gray-800 hover:bg-gray-700 text-gray-300 disabled:opacity-30 border border-gray-700 shadow-md transition-transform active:scale-95"
            aria-label="Swap route origin and destination"
          >
            <ArrowUpDown className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Destination B */}
        <div className="flex items-center space-x-2 bg-gray-950 p-2 rounded-lg border border-gray-800">
          <span className="w-2.5 h-2.5 rounded-full bg-red-500 shrink-0 ring-2 ring-red-500/20" />
          <div className="flex-1 truncate">
            <div className="text-[10px] text-gray-500 font-semibold uppercase">Destination (B)</div>
            <div className="text-xs text-gray-200 truncate">{destinationName || 'Select or drop map pin B'}</div>
          </div>
        </div>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center py-4 text-gray-400 space-x-2">
          <Loader2 className="w-4 h-4 text-indigo-400 animate-spin" />
          <span className="text-xs">Computing optimal route...</span>
        </div>
      )}

      {error && (
        <div className="mt-2.5 p-2 bg-red-950/40 border border-red-900/60 rounded-lg text-red-300 text-[11px]">
          {error}
        </div>
      )}

      {routeInfo && !isLoading && (
        <div className="mt-3 pt-3 border-t border-gray-800 space-y-2">
          <div className="grid grid-cols-2 gap-2">
            <div className="bg-gray-950 p-2.5 rounded-lg border border-gray-800">
              <div className="flex items-center space-x-1.5 text-gray-400 text-[10px] uppercase font-semibold">
                <Navigation2 className="w-3 h-3 text-indigo-400" />
                <span>Total Distance</span>
              </div>
              <div className="text-sm font-bold text-white mt-0.5">{routeInfo.distanceText}</div>
            </div>

            <div className="bg-gray-950 p-2.5 rounded-lg border border-gray-800">
              <div className="flex items-center space-x-1.5 text-gray-400 text-[10px] uppercase font-semibold">
                <Clock className="w-3 h-3 text-emerald-400" />
                <span>Estimated ETA</span>
              </div>
              <div className="text-sm font-bold text-white mt-0.5">{routeInfo.durationText}</div>
            </div>
          </div>

          <button
            onClick={onClear}
            className="w-full py-1.5 mt-1 bg-gray-800 hover:bg-gray-700 text-gray-300 rounded-lg text-xs font-medium border border-gray-700 transition-colors"
          >
            Clear Route
          </button>
        </div>
      )}
    </div>
  );
}
