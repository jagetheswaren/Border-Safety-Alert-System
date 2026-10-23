"use client";

import React, { useEffect, useRef, useState } from 'react';
import { LatLngLiteral } from '../types/map.types';
import { X, Eye, Loader2, AlertCircle } from 'lucide-react';

interface StreetViewPanelProps {
  position: LatLngLiteral | null;
  isOpen: boolean;
  onClose: () => void;
}

export function StreetViewPanel({ position, isOpen, onClose }: StreetViewPanelProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const panoramaRef = useRef<google.maps.StreetViewPanorama | null>(null);
  const [isChecking, setIsChecking] = useState<boolean>(true);
  const [hasCoverage, setHasCoverage] = useState<boolean | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen || !position || typeof window === 'undefined' || !window.google?.maps) {
      return;
    }

    let isCancelled = false;

    // Async Street View check
    const svService = new google.maps.StreetViewService();
    const latLng = new google.maps.LatLng(position.lat, position.lng);

    svService.getPanorama(
      {
        location: latLng,
        radius: 150,
        preference: google.maps.StreetViewPreference.NEAREST,
      },
      (data, status) => {
        if (isCancelled) return;
        setIsChecking(false);
        if (status === google.maps.StreetViewStatus.OK && data?.location?.latLng) {
          setHasCoverage(true);
          setErrorMessage(null);

          if (containerRef.current) {
            panoramaRef.current = new google.maps.StreetViewPanorama(containerRef.current, {
              position: data.location.latLng,
              pov: { heading: 165, pitch: 0 },
              zoom: 1,
              addressControl: true,
              showRoadLabels: true,
              linksControl: true,
              panControl: true,
              enableCloseButton: false,
              fullscreenControl: false,
            });
          }
        } else {
          setHasCoverage(false);
          setErrorMessage('Street View is not available for this location.');
        }
      }
    );

    return () => {
      isCancelled = true;
      if (panoramaRef.current) {
        panoramaRef.current = null;
      }
    };
  }, [isOpen, position]);

  if (!isOpen) return null;

  return (
    <div className="absolute top-20 right-6 z-30 w-80 sm:w-96 bg-gray-900/95 backdrop-blur-md border border-gray-800 text-white rounded-xl shadow-2xl p-4 select-none transition-all animate-in fade-in slide-in-from-right-4">
      <div className="flex items-center justify-between pb-3 border-b border-gray-800">
        <div className="flex items-center space-x-2">
          <Eye className="w-4 h-4 text-blue-400" />
          <h2 className="text-sm font-bold text-white">360° Street View Panorama</h2>
        </div>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-white p-1 rounded hover:bg-gray-800"
          aria-label="Close Street View panel"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <div className="mt-3">
        {isChecking && (
          <div className="h-64 flex flex-col items-center justify-center bg-gray-950 rounded-lg border border-gray-800 text-gray-400 text-xs">
            <Loader2 className="w-6 h-6 animate-spin text-blue-400 mb-2" />
            <span>Scanning for Google Street View coverage...</span>
          </div>
        )}

        {!isChecking && hasCoverage === false && (
          <div className="h-64 flex flex-col items-center justify-center bg-gray-950 rounded-lg border border-gray-800 text-gray-400 text-xs p-4 text-center">
            <AlertCircle className="w-8 h-8 text-amber-500 mb-2" />
            <span className="font-semibold text-gray-300">Coverage Unavailable</span>
            <p className="text-[11px] text-gray-500 mt-1">
              {errorMessage || 'Street View imagery is not available for this remote or tactical coordinate.'}
            </p>
          </div>
        )}

        {/* Panorama Canvas Container */}
        <div
          ref={containerRef}
          className={`w-full h-64 rounded-lg overflow-hidden border border-gray-800 ${
            !isChecking && hasCoverage ? 'block' : 'hidden'
          }`}
        />

        {position && (
          <div className="mt-2 text-[10px] text-gray-400 flex justify-between">
            <span>Location: {position.lat.toFixed(4)}°, {position.lng.toFixed(4)}°</span>
            <span className="text-gray-300">Radius: 150m</span>
          </div>
        )}
      </div>
    </div>
  );
}
