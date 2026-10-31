"use client";

import { FormEvent, useEffect, useRef, useState } from 'react';
import { chatWithAi, checkGeofence } from '@/lib/api';
import { useCurrentLocation } from '@/features/map/hooks/useCurrentLocation';

interface Message { role: 'user' | 'assistant'; content: string; provider?: string; source?: string }

export default function AiAssistantPage() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [prompt, setPrompt] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const controller = useRef<AbortController | null>(null);
  const location = useCurrentLocation(false);
  useEffect(() => () => controller.current?.abort(), []);

  async function send(event: FormEvent) {
    event.preventDefault();
    const message = prompt.trim();
    if (!message || busy) return;
    setBusy(true); setError(null); setPrompt('');
    setMessages(previous => [...previous, { role: 'user', content: message }]);
    const request = new AbortController(); controller.current = request;
    const timeout = setTimeout(() => request.abort(), 185000);
    try {
      const coords = location.coords;
      const fresh = coords && location.timestamp && Date.now() - location.timestamp < 30000;
      let telemetry: Record<string, unknown> = { gps_available: false, risk_state: 'UNKNOWN', zone_state: 'UNKNOWN' };
      if (fresh) {
        const safety = await checkGeofence(coords.lat, coords.lng, request.signal, false, location.accuracy);
        telemetry = { gps_available: true, latitude: coords.lat, longitude: coords.lng, gps_accuracy_m: location.accuracy, risk_state: safety.risk, zone_state: safety.risk };
      }
      const response = await chatWithAi(message, telemetry, request.signal);
      setMessages(previous => [...previous, { role: 'assistant', content: response.reply, provider: response.provider, source: response.source }]);
    } catch (failure) {
      setError(request.signal.aborted ? 'Request stopped or timed out. You can retry.' : failure instanceof Error ? failure.message : 'AI request failed.');
    } finally { clearTimeout(timeout); controller.current = null; setBusy(false); }
  }

  return <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col gap-4 p-4 pb-24 sm:p-6">
    <header><h1 className="text-xl font-semibold">BSAS AI Assistant</h1><p className="mt-1 text-sm text-slate-400">Ask the connected model about BSAS and configured safety information. AI advice does not change geofence decisions.</p></header>
    <div className="rounded-xl border border-slate-700 bg-slate-900 p-3 text-sm">
      <p>{location.coords ? `Location shared for the next question: ${location.coords.lat.toFixed(6)}, ${location.coords.lng.toFixed(6)} · ±${location.accuracy?.toFixed(0)} m` : 'Location is not shared. Safety context is UNKNOWN without a fresh reading.'}</p>
      {location.error && <p role="alert" className="mt-2 text-amber-300">{location.error}</p>}
      <button className="mt-2 rounded bg-sky-800 px-3 py-2" onClick={location.requestLocation} disabled={location.isLoading}>{location.isLoading ? 'Requesting location…' : 'Share my location with AI'}</button>
      {location.tracking && <button className="ml-3 underline" onClick={location.stopTracking}>Stop sharing location</button>}
    </div>
    <div aria-live="polite" className="flex min-h-40 flex-col gap-3">
      {messages.length === 0 && <p className="py-8 text-center text-slate-400">Try “What does BSAS do?” No cloud API key is needed for the configured local model.</p>}
      {messages.map((message, index) => <article key={index} className={`rounded-xl border p-4 ${message.role === 'user' ? 'border-sky-900 bg-sky-950/40' : 'border-slate-700 bg-slate-900'}`}>
        <p className="mb-2 text-xs font-semibold text-slate-400">{message.role === 'user' ? 'You' : message.source === 'ai' ? `${message.provider} · Generated AI response` : 'Database summary · Generative AI unavailable'}</p>
        <p className="whitespace-pre-wrap break-words text-sm">{message.content}</p>
      </article>)}
      {busy && <p role="status" className="text-sky-300">Waiting for the model. Local CPU generation can take a minute.</p>}
      {error && <p role="alert" className="rounded-lg border border-rose-800 p-3 text-rose-300">{error}</p>}
    </div>
    <form onSubmit={send} className="flex items-end gap-2">
      <label className="flex-1"><span className="sr-only">Message to BSAS AI</span><textarea value={prompt} onChange={event => setPrompt(event.target.value)} maxLength={5000} rows={3} disabled={busy} className="w-full rounded-xl border border-slate-600 bg-slate-900 p-3 text-sm" placeholder="Ask BSAS AI…" /></label>
      {busy ? <button type="button" onClick={() => controller.current?.abort()} className="rounded-lg bg-rose-800 px-4 py-3">Stop</button> : <button disabled={!prompt.trim()} className="rounded-lg bg-sky-700 px-4 py-3 disabled:opacity-50">Send</button>}
    </form>
    <p className="text-xs text-slate-500">Chat remains in this page session. Secret provider keys stay on the backend.</p>
  </div>;
}
