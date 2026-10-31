"use client";

import { useEffect, useState } from 'react';

interface InstallPrompt extends Event { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> }

export function PwaSupport() {
  const [installPrompt, setInstallPrompt] = useState<InstallPrompt | null>(null);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    if ('serviceWorker' in navigator && window.isSecureContext) navigator.serviceWorker.register('/sw.js').catch(() => setError('Home-screen support could not start. Reload to retry.'));
    const beforeInstall = (event: Event) => { event.preventDefault(); setInstallPrompt(event as InstallPrompt); };
    const installed = () => setInstallPrompt(null);
    window.addEventListener('beforeinstallprompt', beforeInstall);
    window.addEventListener('appinstalled', installed);
    return () => { window.removeEventListener('beforeinstallprompt', beforeInstall); window.removeEventListener('appinstalled', installed); };
  }, []);
  async function install() {
    if (!installPrompt) return;
    try { await installPrompt.prompt(); await installPrompt.userChoice; setInstallPrompt(null); }
    catch { setError('Use your browser menu to install BSAS or add it to the home screen.'); }
  }
  return <>{installPrompt && <button onClick={install} className="fixed bottom-20 right-3 z-50 rounded-lg border border-sky-500 bg-slate-950 px-3 py-2 text-xs text-sky-200 shadow-xl">Install BSAS</button>}{error && <p role="status" className="fixed bottom-20 right-3 z-50 max-w-xs rounded bg-slate-900 p-3 text-xs text-amber-200" onClick={() => setError(null)}>{error}</p>}</>;
}
