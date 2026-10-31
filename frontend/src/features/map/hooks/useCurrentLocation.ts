"use client";
import { useState, useEffect, useCallback, useRef } from 'react';
import { UserLocationState } from '../types/map.types';

export function useCurrentLocation(autoLocate = false) {
  const [state, setState] = useState<UserLocationState>({ coords: null, accuracy: null, heading: null, speed: null, timestamp: null, isLoading: false, error: null, permissionDenied: false });
  const [tracking, setTracking] = useState(false);
  const watch = useRef<number | null>(null);
  const generation = useRef(0);
  const watchdog = useRef<ReturnType<typeof setTimeout> | null>(null);
  const stopTracking = useCallback(() => {
    generation.current++;
    if (watchdog.current) clearTimeout(watchdog.current);
    if (watch.current !== null) navigator.geolocation?.clearWatch(watch.current);
    watch.current = null;
    setTracking(false);
    setState(s => ({ ...s, coords: null, accuracy: null, timestamp: null, isLoading: false, error: null, permissionDenied: false }));
  }, []);
  const requestLocation = useCallback(() => {
    const id = ++generation.current;
    if (watchdog.current) clearTimeout(watchdog.current);
    if (watch.current !== null) navigator.geolocation?.clearWatch(watch.current);
    watch.current = null;
    if (!window.isSecureContext || !navigator.geolocation) {
      setState(s => ({ ...s, coords: null, timestamp: null, isLoading: false, error: !window.isSecureContext ? 'Location requires HTTPS or localhost.' : 'Geolocation is not supported by this browser.' }));
      return;
    }
    let latestTimestamp = 0;
    setTracking(true);
    setState(s => ({ ...s, coords: null, timestamp: null, isLoading: true, error: null, permissionDenied: false }));
    const success = (pos: GeolocationPosition) => {
      if (id !== generation.current) return;
      if (!Number.isFinite(pos.timestamp) || Date.now() - pos.timestamp > 30000 || pos.timestamp > Date.now() + 5000 || pos.timestamp < latestTimestamp) return;
      const { latitude: lat, longitude: lng, accuracy } = pos.coords;
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180 || !Number.isFinite(accuracy) || accuracy < 0) return;
      if (watchdog.current) clearTimeout(watchdog.current);
      latestTimestamp = pos.timestamp;
      setState({ coords: { lat, lng }, accuracy, heading: pos.coords.heading, speed: pos.coords.speed, timestamp: pos.timestamp, isLoading: false, error: null, permissionDenied: false });
    };
    const failure = (err: GeolocationPositionError) => {
      if (id !== generation.current) return;
      if (watchdog.current) clearTimeout(watchdog.current);
      const denied = err.code === 1;
      if (denied) { generation.current++; if (watch.current !== null) navigator.geolocation.clearWatch(watch.current); watch.current = null; setTracking(false); }
      setState(s => ({ ...s, coords: null, timestamp: null, accuracy: null, isLoading: false, permissionDenied: denied, error: denied ? 'Location denied. Open site settings → Location → Allow, enable device location, then retry.' : err.code === 3 ? 'Location timed out. Enable device location and retry; tracking will recover when a reading arrives.' : 'Position unavailable. Enable device location and check your connection.' }));
    };
    watchdog.current = setTimeout(() => { if (id === generation.current && !latestTimestamp) failure({ code: 3 } as GeolocationPositionError); }, 20000);
    navigator.geolocation.getCurrentPosition(success, err => { if (!latestTimestamp || err.code === 1) failure(err); }, { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 });
    watch.current = navigator.geolocation.watchPosition(success, failure, { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 });
  }, []);
  const invalidate = useCallback(() => { generation.current++; if (watchdog.current) clearTimeout(watchdog.current); if (watch.current !== null) navigator.geolocation?.clearWatch(watch.current); }, []);
  useEffect(() => {
    let active = true;
    if (autoLocate) queueMicrotask(() => { if (active) requestLocation(); });
    const timer = setInterval(() => setState(s => s.timestamp && Date.now() - s.timestamp > 30000 ? { ...s, coords: null, timestamp: null, error: 'Location is out of date. Waiting for a fresh reading.' } : s), 5000);
    return () => { active = false; invalidate(); clearInterval(timer); };
  }, [autoLocate, requestLocation, invalidate]);
  return { ...state, tracking, requestLocation, stopTracking };
}
