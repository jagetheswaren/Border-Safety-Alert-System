"use client";

import React, { useState, useEffect, useRef } from 'react';
import { Search, X, MapPin, Loader2 } from 'lucide-react';
import { PlaceResult } from '../types/map.types';
import { getPlacePredictions, fetchPlaceDetails } from '../services/places.service';

interface PlaceSearchProps {
  onPlaceSelect: (place: PlaceResult) => void;
  className?: string;
}

export function PlaceSearch({ onPlaceSelect, className = '' }: PlaceSearchProps) {
  const [input, setInput] = useState('');
  const [predictions, setPredictions] = useState<google.maps.places.AutocompletePrediction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const sessionTokenRef = useRef<google.maps.places.AutocompleteSessionToken | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Initialize session token when typing starts
  const ensureSessionToken = () => {
    if (!sessionTokenRef.current && typeof window !== 'undefined' && window.google?.maps?.places) {
      sessionTokenRef.current = new window.google.maps.places.AutocompleteSessionToken();
    }
  };

  const handleInputChange = (val: string) => {
    setInput(val);
    if (!val.trim()) {
      setPredictions([]);
      setIsOpen(false);
    }
  };

  useEffect(() => {
    if (!input.trim()) {
      return;
    }

    ensureSessionToken();
    const timeout = setTimeout(async () => {
      setIsLoading(true);
      try {
        const results = await getPlacePredictions(input, sessionTokenRef.current || undefined);
        setPredictions(results);
        setIsOpen(results.length > 0);
      } catch (err) {
        console.error('Autocomplete prediction error:', err);
      } finally {
        setIsLoading(false);
      }
    }, 280); // Debounce requests

    return () => clearTimeout(timeout);
  }, [input]);

  // Click outside listener
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelectPrediction = async (prediction: google.maps.places.AutocompletePrediction) => {
    setInput(prediction.description);
    setIsOpen(false);
    setIsLoading(true);

    try {
      const details = await fetchPlaceDetails(prediction.place_id, sessionTokenRef.current || undefined);
      if (details) {
        onPlaceSelect(details);
      }
    } catch (err) {
      console.error('Error fetching place details:', err);
    } finally {
      setIsLoading(false);
      // Reset session token after completion per Google Places API best practices
      sessionTokenRef.current = null;
    }
  };

  const handleClear = () => {
    setInput('');
    setPredictions([]);
    setIsOpen(false);
    sessionTokenRef.current = null;
  };

  return (
    <div ref={containerRef} className={`relative z-30 w-full max-w-md ${className}`}>
      <div className="relative flex items-center">
        <Search className="absolute left-3.5 w-4 h-4 text-gray-400 pointer-events-none" />
        <input
          type="text"
          value={input}
          onChange={(e) => handleInputChange(e.target.value)}
          onFocus={() => input.trim() && setPredictions.length > 0 && setIsOpen(true)}
          placeholder="Search place, city, hospital, police post..."
          className="w-full pl-10 pr-9 py-2 bg-gray-900/95 backdrop-blur-md border border-gray-700/80 rounded-xl text-white placeholder-gray-400 text-xs shadow-xl focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all"
        />
        {isLoading ? (
          <Loader2 className="absolute right-3 w-4 h-4 text-blue-400 animate-spin" />
        ) : input ? (
          <button
            onClick={handleClear}
            className="absolute right-3 text-gray-400 hover:text-white p-0.5"
            aria-label="Clear place search"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        ) : null}
      </div>

      {isOpen && predictions.length > 0 && (
        <ul className="absolute top-full left-0 right-0 mt-1.5 bg-gray-900 border border-gray-800 rounded-xl shadow-2xl overflow-hidden py-1 max-h-64 overflow-y-auto divide-y divide-gray-800/60 z-40 text-xs">
          {predictions.map((p) => (
            <li
              key={p.place_id}
              onClick={() => handleSelectPrediction(p)}
              className="px-3.5 py-2 hover:bg-gray-800/80 cursor-pointer text-gray-200 flex items-start space-x-2.5 transition-colors"
            >
              <MapPin className="w-3.5 h-3.5 text-blue-400 shrink-0 mt-0.5" />
              <div>
                <span className="font-medium text-white block">
                  {p.structured_formatting?.main_text || p.description}
                </span>
                <span className="text-[10px] text-gray-400 block truncate">
                  {p.structured_formatting?.secondary_text || ''}
                </span>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
