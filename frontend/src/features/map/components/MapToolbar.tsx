"use client";

import React from 'react';
import {
  Search,
  Crosshair,
  Route as RouteIcon,
  Eye,
  Car,
  Maximize2,
  Minimize2,
  Shield,
  AlertTriangle,
  Radio,
  Wifi,
  WifiOff,
  RefreshCw,
} from 'lucide-react';
import { MapTypeMode, MapLayersVisibility, MapProvider } from '../types/map.types';

interface MapToolbarProps {
  mapType: MapTypeMode;
  onChangeMapType: (type: MapTypeMode) => void;
  layers: MapLayersVisibility;
  onToggleLayer: (layerKey: keyof MapLayersVisibility) => void;
  onLocateUser: () => void;
  isLocating: boolean;
  onToggleSearch: () => void;
  isSearchOpen: boolean;
  onToggleRoute: () => void;
  isRouteOpen: boolean;
  onToggleStreetView: () => void;
  isStreetViewOpen: boolean;
  activeProvider: MapProvider;
  onToggleProvider: () => void;
  onRefreshData?: () => void;
  isFullscreen: boolean;
  onToggleFullscreen: () => void;
}

export function MapToolbar({
  mapType,
  onChangeMapType,
  layers,
  onToggleLayer,
  onLocateUser,
  isLocating,
  onToggleSearch,
  isSearchOpen,
  onToggleRoute,
  isRouteOpen,
  onToggleStreetView,
  isStreetViewOpen,
  activeProvider,
  onToggleProvider,
  onRefreshData,
  isFullscreen,
  onToggleFullscreen,
}: MapToolbarProps) {
  return (
    <div className="absolute top-4 left-6 z-20 flex flex-wrap items-center gap-1.5 bg-gray-900/95 backdrop-blur-md border border-gray-800 p-1.5 rounded-xl shadow-2xl text-xs text-white">
      {/* Search Toggle */}
      <button
        onClick={onToggleSearch}
        title="Search places, landmarks, POIs"
        className={`flex items-center space-x-1 px-2.5 py-1.5 rounded-lg border transition-colors ${
          isSearchOpen
            ? 'bg-blue-600 text-white border-blue-500 shadow-md'
            : 'bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700'
        }`}
      >
        <Search className="w-3.5 h-3.5" />
        <span className="hidden sm:inline font-medium">Search</span>
      </button>

      {/* Current Location GPS Button */}
      <button
        onClick={onLocateUser}
        disabled={isLocating}
        title="Locate my position (GPS)"
        className={`flex items-center space-x-1 px-2.5 py-1.5 rounded-lg border bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700 transition-colors ${
          isLocating ? 'animate-pulse text-blue-400' : ''
        }`}
      >
        <Crosshair className={`w-3.5 h-3.5 ${isLocating ? 'animate-spin' : ''}`} />
        <span className="hidden sm:inline font-medium">GPS Fix</span>
      </button>

      {/* Route Planner Toggle */}
      <button
        onClick={onToggleRoute}
        title="A-to-B Route Navigation Planner"
        className={`flex items-center space-x-1 px-2.5 py-1.5 rounded-lg border transition-colors ${
          isRouteOpen
            ? 'bg-indigo-600 text-white border-indigo-500 shadow-md'
            : 'bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700'
        }`}
      >
        <RouteIcon className="w-3.5 h-3.5" />
        <span className="hidden sm:inline font-medium">Route</span>
      </button>

      {/* Street View Toggle */}
      <button
        onClick={onToggleStreetView}
        title="360° Street View Panorama"
        className={`flex items-center space-x-1 px-2.5 py-1.5 rounded-lg border transition-colors ${
          isStreetViewOpen
            ? 'bg-blue-600 text-white border-blue-500 shadow-md'
            : 'bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700'
        }`}
      >
        <Eye className="w-3.5 h-3.5" />
        <span className="hidden sm:inline font-medium">Street View</span>
      </button>

      <span className="w-px h-5 bg-gray-800 mx-0.5" />

      {/* Traffic Toggle */}
      <button
        onClick={() => onToggleLayer('traffic')}
        title={layers.traffic ? 'Traffic Layer ON' : 'Traffic Layer OFF'}
        className={`flex items-center space-x-1 px-2.5 py-1.5 rounded-lg border transition-colors ${
          layers.traffic
            ? 'bg-emerald-600/90 text-white border-emerald-500'
            : 'bg-gray-800 text-gray-400 border-gray-700/80 hover:bg-gray-700'
        }`}
      >
        <Car className="w-3.5 h-3.5" />
        <span className="hidden md:inline font-medium">Traffic</span>
      </button>

      {/* Map Type Mode Switcher */}
      <div className="flex items-center bg-gray-950 rounded-lg p-0.5 border border-gray-800">
        {(['roadmap', 'satellite', 'hybrid', 'terrain'] as MapTypeMode[]).map((type) => (
          <button
            key={type}
            onClick={() => onChangeMapType(type)}
            className={`px-2 py-1 rounded text-[10px] font-semibold uppercase tracking-wider transition-colors ${
              mapType === type
                ? 'bg-blue-600 text-white shadow-sm'
                : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            {type}
          </button>
        ))}
      </div>

      <span className="w-px h-5 bg-gray-800 mx-0.5" />

      {/* Layer Toggles */}
      <button
        onClick={() => onToggleLayer('borders')}
        title="Toggle Monitored Borders"
        className={`p-1.5 rounded-lg border transition-colors ${
          layers.borders
            ? 'bg-blue-600/20 text-blue-400 border-blue-500/40'
            : 'bg-gray-800 text-gray-500 border-gray-700/60'
        }`}
      >
        <Shield className="w-3.5 h-3.5" />
      </button>

      <button
        onClick={() => onToggleLayer('incidents')}
        title="Toggle Incidents"
        className={`p-1.5 rounded-lg border transition-colors ${
          layers.incidents
            ? 'bg-red-600/20 text-red-400 border-red-500/40'
            : 'bg-gray-800 text-gray-500 border-gray-700/60'
        }`}
      >
        <AlertTriangle className="w-3.5 h-3.5" />
      </button>

      <button
        onClick={() => onToggleLayer('devices')}
        title="Toggle Field Devices"
        className={`p-1.5 rounded-lg border transition-colors ${
          layers.devices
            ? 'bg-emerald-600/20 text-emerald-400 border-emerald-500/40'
            : 'bg-gray-800 text-gray-500 border-gray-700/60'
        }`}
      >
        <Radio className="w-3.5 h-3.5" />
      </button>

      {/* Refresh Button */}
      {onRefreshData && (
        <button
          onClick={onRefreshData}
          title="Refresh spatial telemetry data"
          className="p-1.5 rounded-lg border bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700 transition-colors"
        >
          <RefreshCw className="w-3.5 h-3.5" />
        </button>
      )}

      {/* Fullscreen Toggle */}
      <button
        onClick={onToggleFullscreen}
        title={isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen'}
        className="p-1.5 rounded-lg border bg-gray-800 text-gray-300 border-gray-700/80 hover:bg-gray-700 transition-colors"
      >
        {isFullscreen ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
      </button>

      {/* Online / Offline Provider Badge */}
      <button
        onClick={onToggleProvider}
        title="Click to switch map engine (Google Maps / Offline MapLibre)"
        className={`flex items-center space-x-1.5 px-2.5 py-1 rounded-lg text-[10px] font-bold tracking-wider border uppercase transition-colors ${
          activeProvider === 'google'
            ? 'bg-emerald-950/80 text-emerald-400 border-emerald-700/80 hover:bg-emerald-900/80'
            : 'bg-amber-950/80 text-amber-400 border-amber-700/80 hover:bg-amber-900/80'
        }`}
      >
        {activeProvider === 'google' ? (
          <>
            <Wifi className="w-3 h-3 text-emerald-400" />
            <span>ONLINE</span>
          </>
        ) : (
          <>
            <WifiOff className="w-3 h-3 text-amber-400" />
            <span>OFFLINE</span>
          </>
        )}
      </button>
    </div>
  );
}
