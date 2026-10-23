"use client";

import { useState, useEffect, useCallback } from 'react';
import { IncidentMarkerItem, DeviceMarkerItem } from '../types/map.types';

const API_BASE = (process.env.NEXT_PUBLIC_API_BASE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');

interface RawIncident {
  id: string;
  incident_number?: string;
  title: string;
  category: string;
  severity: string;
  status: string;
  latitude: number;
  longitude: number;
  description?: string;
  reported_by?: string;
  assigned_to?: string;
  created_at?: string;
}

interface RawLocationItem {
  id: string;
  device_id?: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  bearing?: number;
  timestamp?: string;
}

export function useIncidents(pollIntervalMs: number = 30000) {
  const [incidents, setIncidents] = useState<IncidentMarkerItem[]>([]);
  const [devices, setDevices] = useState<DeviceMarkerItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadOperationalData = useCallback(async () => {
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;

      // 1. Fetch Incidents
      let items: IncidentMarkerItem[] = [];
      try {
        const res = await fetch(`${API_BASE}/incidents/?limit=100`, { headers, cache: 'no-store' });
        if (res.ok) {
          const data = await res.json();
          items = ((data.items as RawIncident[]) || []).map((inc) => ({
            id: inc.id,
            incidentNumber: inc.incident_number,
            title: inc.title,
            category: inc.category,
            severity: inc.severity,
            status: inc.status,
            latitude: inc.latitude,
            longitude: inc.longitude,
            description: inc.description,
            reportedBy: inc.reported_by,
            assignedTo: inc.assigned_to,
            createdAt: inc.created_at || new Date().toISOString(),
          }));
        }
      } catch (e) {
        console.warn('Could not fetch incidents from backend', e);
      }

      // 2. Fetch Latest Device Breadcrumbs
      const deviceItems: DeviceMarkerItem[] = [];
      try {
        const devRes = await fetch(`${API_BASE}/locations/latest?limit=50`, { headers, cache: 'no-store' });
        if (devRes.ok) {
          const devData = (await devRes.json()) as RawLocationItem[];
          // Filter latest per device
          const seen = new Set<string>();
          for (const item of devData) {
            const devId = item.device_id || item.id;
            if (!seen.has(devId)) {
              seen.add(devId);
              deviceItems.push({
                id: item.id,
                deviceId: devId,
                latitude: item.latitude,
                longitude: item.longitude,
                accuracy: item.accuracy,
                speed: item.speed,
                heading: item.bearing,
                timestamp: item.timestamp || new Date().toISOString(),
              });
            }
          }
        }
      } catch (e) {
        console.warn('Could not fetch device locations from backend', e);
      }

      setIncidents(items);
      setDevices(deviceItems);
      setError(null);
    } catch (err: unknown) {
      console.error('Error fetching live operations data:', err);
      setError(err instanceof Error ? err.message : 'Failed to update live incidents');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const init = async () => {
      await Promise.resolve();
      await loadOperationalData();
    };
    init();

    if (pollIntervalMs > 0) {
      const interval = setInterval(loadOperationalData, pollIntervalMs);
      return () => clearInterval(interval);
    }
  }, [loadOperationalData, pollIntervalMs]);

  return {
    incidents,
    devices,
    isLoading,
    error,
    refreshIncidents: loadOperationalData,
  };
}
