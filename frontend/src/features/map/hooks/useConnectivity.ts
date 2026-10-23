"use client";

import { useState, useEffect, useCallback } from 'react';
import { MapProvider } from '../types/map.types';

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');

export function useConnectivity() {
  const [isOnline, setIsOnline] = useState<boolean>(true);
  const [backendReachable, setBackendReachable] = useState<boolean>(true);
  const [activeProvider, setActiveProvider] = useState<MapProvider>('google');
  const [manualOffline, setManualOffline] = useState<boolean>(false);
  const [lastCheck, setLastCheck] = useState<number>(0);

  const checkConnectivity = useCallback(async () => {
    if (typeof window === 'undefined') return;

    const navOnline = navigator.onLine;
    setIsOnline(navOnline);

    if (!navOnline) {
      setBackendReachable(false);
      setActiveProvider('offline');
      return;
    }

    if (manualOffline) {
      setActiveProvider('offline');
      return;
    }

    // Ping backend with quick 4-second timeout
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);
      const res = await fetch(`${API_BASE}/health`, {
        signal: controller.signal,
        cache: 'no-store',
      });
      clearTimeout(timeoutId);

      const reachable = res.status < 500;
      setBackendReachable(reachable);

      // Check Google Maps API Key existence
      const hasGoogleKey = Boolean(process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY);
      if (hasGoogleKey && reachable) {
        setActiveProvider('google');
      } else {
        setActiveProvider('offline');
      }
    } catch {
      setBackendReachable(false);
      // If backend is unreachable, we can still show Google maps if internet is up, or fallback
      const hasGoogleKey = Boolean(process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY);
      setActiveProvider(hasGoogleKey && navOnline ? 'google' : 'offline');
    } finally {
      setLastCheck(Date.now());
    }
  }, [manualOffline]);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    window.addEventListener('online', checkConnectivity);
    window.addEventListener('offline', checkConnectivity);

    const triggerCheck = async () => {
      await Promise.resolve();
      await checkConnectivity();
    };
    triggerCheck();
    const interval = setInterval(triggerCheck, 25000);

    return () => {
      window.removeEventListener('online', checkConnectivity);
      window.removeEventListener('offline', checkConnectivity);
      clearInterval(interval);
    };
  }, [checkConnectivity]);

  const toggleManualProvider = () => {
    setManualOffline((prev) => {
      const next = !prev;
      setActiveProvider(next ? 'offline' : 'google');
      return next;
    });
  };

  return {
    isOnline,
    backendReachable,
    activeProvider,
    manualOffline,
    lastCheck,
    toggleManualProvider,
    toggleProvider: toggleManualProvider,
    checkConnectivity,
  };
}
