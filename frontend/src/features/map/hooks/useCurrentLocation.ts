"use client";

import { useState, useEffect, useCallback } from 'react';
import { UserLocationState } from '../types/map.types';

export function useCurrentLocation(autoLocate: boolean = false) {
  const [state, setState] = useState<UserLocationState>({
    coords: null,
    accuracy: null,
    heading: null,
    speed: null,
    timestamp: null,
    isLoading: false,
    error: null,
    permissionDenied: false,
  });

  const requestLocation = useCallback(() => {
    if (typeof window === 'undefined' || !navigator.geolocation) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: 'Geolocation is not supported by your browser.',
        permissionDenied: false,
      }));
      return;
    }

    setState((prev) => ({ ...prev, isLoading: true, error: null }));

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setState({
          coords: { lat: pos.coords.latitude, lng: pos.coords.longitude },
          accuracy: pos.coords.accuracy,
          heading: pos.coords.heading,
          speed: pos.coords.speed,
          timestamp: pos.timestamp,
          isLoading: false,
          error: null,
          permissionDenied: false,
        });
      },
      (err) => {
        let msg = 'Unable to retrieve your current location.';
        let denied = false;
        if (err.code === err.PERMISSION_DENIED) {
          msg = 'Location permission is required to show your current position.';
          denied = true;
        } else if (err.code === err.POSITION_UNAVAILABLE) {
          msg = 'Location service is currently unavailable.';
        } else if (err.code === err.TIMEOUT) {
          msg = 'Location request timed out. Please try again.';
        }
        setState((prev) => ({
          ...prev,
          isLoading: false,
          error: msg,
          permissionDenied: denied,
        }));
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 5000,
      }
    );
  }, []);

  useEffect(() => {
    if (autoLocate) {
      const init = async () => {
        await Promise.resolve();
        requestLocation();
      };
      init();
    }
  }, [autoLocate, requestLocation]);

  return {
    ...state,
    requestLocation,
  };
}
