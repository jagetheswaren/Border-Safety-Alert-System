"use client";
import { useEffect, useRef, useState } from 'react';
import { checkGeofence, GeofenceResult } from '@/lib/api';
import { LatLngLiteral, SafetyZoneFeature } from '../types/map.types';

export function LocationSafetyPanel({ coords, accuracy, timestamp, zones, tracking, error, isLocating, requestLocation, stopTracking }: { coords: LatLngLiteral | null; accuracy: number | null; timestamp: number | null; zones: SafetyZoneFeature[]; tracking: boolean; error: string | null; isLocating: boolean; requestLocation: () => void; stopTracking: () => void }) {
  const [evaluation, setEvaluation] = useState<{ result?: GeofenceResult; error?: string; key: string } | null>(null);
  const [recordAlerts, setRecordAlerts] = useState(false);
  const [notifications, setNotifications] = useState(false);
  const [notificationError, setNotificationError] = useState<string | null>(null);
  const lastNotification = useRef('');
  async function enableNotifications() {
    if (!('Notification' in window)) { setNotificationError('Browser notifications are not supported. Keep this page open for visible alerts.'); return; }
    try {
      const permission = await Notification.requestPermission();
      setNotifications(permission === 'granted');
      setNotificationError(permission === 'granted' ? null : 'Notifications were not allowed. Visible warnings remain available here.');
    } catch { setNotificationError('Notifications are unavailable in this browser.'); }
  }
  const key = coords ? `${coords.lat},${coords.lng},${accuracy}` : '';
  useEffect(() => {
    if (!coords) return;
    let active = true;
    let controller: AbortController | null = null;
    const evaluate = async () => {
      controller = new AbortController();
      const timeout = setTimeout(() => controller?.abort(), 15000);
      try {
        const result = await checkGeofence(coords.lat, coords.lng, controller.signal, recordAlerts, accuracy);
        if (active) {
          setEvaluation({ result, key });
          const warningKey = ['WARNING', 'CRITICAL'].includes(result.risk) ? `${result.risk}:${result.nearest_zone_id}` : '';
          if (notifications && warningKey && warningKey !== lastNotification.current) {
            lastNotification.current = warningKey;
            try {
              const registration = 'serviceWorker' in navigator ? await navigator.serviceWorker.getRegistration() : null;
              const title = `BSAS ${result.risk}`;
              const options = { body: 'You are near or inside a configured safety zone. Open BSAS to review location accuracy and distance.', tag: 'bsas-geofence' };
              if (registration) await registration.showNotification(title, options); else new Notification(title, options);
            } catch { if (active) setNotificationError('This browser could not display a notification. Keep BSAS open for visible warnings.'); }
          }
          if (!warningKey) lastNotification.current = '';
        }
      } catch (err) {
        if (active) setEvaluation({ error: err instanceof Error ? err.message : 'Safety check failed', key });
      } finally { clearTimeout(timeout); }
    };
    void evaluate();
    const timer = setInterval(() => void evaluate(), 20000);
    return () => { active = false; clearInterval(timer); controller?.abort(); };
  }, [coords, key, recordAlerts, notifications, accuracy]);
  const current = key && evaluation?.key === key ? evaluation : null;
  const risk = current?.result?.risk ?? 'UNKNOWN';
  const zone = zones.find(z => String(z.id) === String(current?.result?.nearest_zone_id));
  return <section aria-label="Location and backend safety" className="absolute bottom-10 left-3 z-20 max-w-[calc(100%-5rem)] w-80 rounded-xl border border-slate-600 bg-slate-950/95 p-3 text-xs text-slate-200 shadow-xl">
    <div role="status" aria-live="polite" className={risk === 'CRITICAL' ? 'text-rose-400 font-bold' : risk === 'WARNING' ? 'text-amber-300 font-bold' : 'font-bold'}>Safety: {risk}</div>
    {coords ? <><p>Latitude: {coords.lat.toFixed(6)} · Longitude: {coords.lng.toFixed(6)}</p><p>Reported accuracy: ±{accuracy?.toFixed(0) ?? '?'} m{accuracy !== null && accuracy > 100 ? ' · Approximate location' : ''}</p></> : <p>No current location. Map overview is not your GPS position.</p>}
    {timestamp && coords && <p>Updated: {new Date(timestamp).toLocaleTimeString()}</p>}
    <p>{isLocating ? 'Requesting device location…' : tracking ? 'Tracking enabled · while this page is active' : 'Tracking stopped'}</p>
    {error && <p role="alert" className="text-amber-300">{error}</p>}
    <p>Nearest configured zone: {zone?.name ?? current?.result?.nearest_zone_id ?? 'Unknown'}</p>
    <p>Boundary distance: {current?.result?.distance_m == null ? 'Unknown' : `${current.result.distance_m.toFixed(0)} m`}</p>
    {coords && !current && <p>Checking backend safety…</p>}
    {current?.error && <p role="alert" className="text-rose-300">{current.error} · Safety unavailable.</p>}
    {current?.result?.reason && <p>{current.result.reason}</p>}
    {current?.result?.alert_id && <p className="text-sky-300">Warning saved to operator alert history.</p>}
    <label className="mt-2 flex items-start gap-2"><input type="checkbox" checked={recordAlerts} onChange={event => setRecordAlerts(event.target.checked)} />Save warning alerts with my location to operator history</label>
    <button onClick={enableNotifications} className="mt-2 underline">{notifications ? 'Browser alerts enabled' : 'Enable browser alerts'}</button>
    {notificationError && <p role="status" className="text-amber-300">{notificationError}</p>}
    <div className="mt-2 flex gap-3"><button onClick={requestLocation} className="rounded bg-blue-700 px-3 py-2">{tracking ? 'My Current Location / Retry' : 'Start Tracking / My Location'}</button>{tracking && <button onClick={stopTracking} className="underline">Stop tracking</button>}</div>
  </section>;
}
