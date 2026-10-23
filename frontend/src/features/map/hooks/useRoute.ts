"use client";

import { useState, useCallback } from 'react';
import { LatLngLiteral, RouteInfo } from '../types/map.types';
import { calculateRoute } from '../services/routes.service';
import { reverseGeocode } from '../services/geocoding.service';

export function useRoute() {
  const [origin, setOrigin] = useState<LatLngLiteral | null>(null);
  const [destination, setDestination] = useState<LatLngLiteral | null>(null);
  const [originName, setOriginName] = useState<string>('');
  const [destinationName, setDestinationName] = useState<string>('');
  const [routeInfo, setRouteInfo] = useState<RouteInfo | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const calculateActiveRoute = useCallback(async (start: LatLngLiteral, end: LatLngLiteral) => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await calculateRoute(start, end);
      if (res) {
        setRouteInfo(res);
      } else {
        setError('Could not calculate a navigable route between these locations.');
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Route calculation failed.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const setOriginPoint = useCallback(async (point: LatLngLiteral, name?: string) => {
    setOrigin(point);
    if (name) {
      setOriginName(name);
    } else {
      const addr = await reverseGeocode(point);
      setOriginName(addr);
    }
    if (destination) {
      calculateActiveRoute(point, destination);
    }
  }, [destination, calculateActiveRoute]);

  const setDestinationPoint = useCallback(async (point: LatLngLiteral, name?: string) => {
    setDestination(point);
    if (name) {
      setDestinationName(name);
    } else {
      const addr = await reverseGeocode(point);
      setDestinationName(addr);
    }
    if (origin) {
      calculateActiveRoute(origin, point);
    }
  }, [origin, calculateActiveRoute]);

  const swapPoints = useCallback(() => {
    if (!origin || !destination) return;
    const oldOrigin = origin;
    const oldOriginName = originName;
    const oldDest = destination;
    const oldDestName = destinationName;

    setOrigin(oldDest);
    setOriginName(oldDestName);
    setDestination(oldOrigin);
    setDestinationName(oldOriginName);

    calculateActiveRoute(oldDest, oldOrigin);
  }, [origin, destination, originName, destinationName, calculateActiveRoute]);

  const clearRoute = useCallback(() => {
    setOrigin(null);
    setDestination(null);
    setOriginName('');
    setDestinationName('');
    setRouteInfo(null);
    setError(null);
  }, []);

  return {
    origin,
    destination,
    originName,
    destinationName,
    routeInfo,
    isLoading,
    error,
    setOriginPoint,
    setDestinationPoint,
    swapPoints,
    swapOriginDestination: swapPoints,
    clearRoute,
  };
}
