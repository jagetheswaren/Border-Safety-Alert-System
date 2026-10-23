"use client";

import React from 'react';
import { BorderFeature, LatLngLiteral } from '../types/map.types';
import { calculateDistanceToFeature } from '../services/maps.service';
import { X, MapPin, Database, Calendar, Navigation } from 'lucide-react';

interface BorderMetadataPanelProps {
  border: BorderFeature | null;
  userLocation: LatLngLiteral | null;
  onClose: () => void;
  onCenterBoundary?: (border: BorderFeature) => void;
}

export function BorderMetadataPanel({
  border,
  userLocation,
  onClose,
  onCenterBoundary,
}: BorderMetadataPanelProps) {
  if (!border) return null;

  const props = border.properties;

  const distanceInfo = userLocation
    ? calculateDistanceToFeature(userLocation, border)
    : null;

  const distanceText = distanceInfo
    ? distanceInfo.isInside
      ? 'INSIDE RESTRICTED SECTOR'
      : `${(distanceInfo.distanceMeters / 1000).toFixed(2)} km away`
    : 'No GPS position fix';

  const riskColor =
    props.risk_level === 'CRITICAL'
      ? 'text-red-400 bg-red-950/60 border-red-800'
      : props.risk_level === 'WARNING'
      ? 'text-amber-400 bg-amber-950/60 border-amber-800'
      : 'text-blue-400 bg-blue-950/60 border-blue-800';

  return (
    <div className="absolute top-20 left-6 z-20 w-84 bg-gray-900/95 backdrop-blur-md border border-gray-800 text-white rounded-xl shadow-2xl p-4 text-xs select-none transition-all animate-in fade-in slide-in-from-left-4">
      <div className="flex items-start justify-between pb-3 border-b border-gray-800">
        <div>
          <div className="flex items-center space-x-2">
            <span className={`px-2 py-0.5 rounded text-[10px] font-semibold border ${riskColor}`}>
              {props.risk_level || 'MONITORED'}
            </span>
            <span className="text-gray-400 text-[10px] uppercase tracking-wider">{props.boundary_type}</span>
          </div>
          <h2 className="text-sm font-bold text-white mt-1.5 leading-snug">{props.boundary_name}</h2>
        </div>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-white p-1 rounded hover:bg-gray-800"
          aria-label="Close border details panel"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <div className="py-3 space-y-2.5 text-gray-300">
        <div className="flex items-start space-x-2">
          <MapPin className="w-3.5 h-3.5 text-gray-500 mt-0.5 shrink-0" />
          <div>
            <div className="text-[10px] text-gray-500 uppercase font-medium">Demarcated Sectors</div>
            <div className="text-xs text-gray-200">
              {props.region_a || 'Sector Alpha'} &harr; {props.region_b || 'Sector Bravo'}
            </div>
          </div>
        </div>

        {props.description && (
          <p className="text-[11px] text-gray-400 italic bg-gray-950/50 p-2 rounded border border-gray-800/80">
            &ldquo;{props.description}&rdquo;
          </p>
        )}

        <div className="bg-gray-950 p-2.5 rounded-lg border border-gray-800">
          <div className="text-[10px] text-gray-500 uppercase font-medium mb-1 flex items-center justify-between">
            <span>Proximity to Your Fix</span>
            <Navigation className="w-3 h-3 text-blue-400" />
          </div>
          <div className={`text-xs font-semibold ${distanceInfo?.isInside ? 'text-red-400' : 'text-white'}`}>
            {distanceText}
          </div>
        </div>

        <div className="space-y-1.5 text-[11px] text-gray-400 pt-1">
          <div className="flex items-center justify-between">
            <span className="flex items-center space-x-1.5 text-gray-500">
              <Database className="w-3 h-3" />
              <span>Dataset Source</span>
            </span>
            <span className="text-gray-300 font-mono text-[10px]">{props.source || 'BSAS-SURVEY-v2.0'}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="flex items-center space-x-1.5 text-gray-500">
              <Calendar className="w-3 h-3" />
              <span>Effective Date</span>
            </span>
            <span className="text-gray-300">{props.source_date || '2026-10-01'}</span>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-gray-500">Feature Identifier</span>
            <span className="font-mono text-[10px] text-gray-400">{props.id}</span>
          </div>
        </div>
      </div>

      {onCenterBoundary && (
        <button
          onClick={() => onCenterBoundary(border)}
          className="w-full mt-2 py-1.5 bg-blue-600/20 hover:bg-blue-600/30 text-blue-400 rounded-lg text-xs font-medium border border-blue-500/30 transition-colors flex items-center justify-center space-x-1.5"
        >
          <Navigation className="w-3.5 h-3.5" />
          <span>Center Boundary in View</span>
        </button>
      )}
    </div>
  );
}
