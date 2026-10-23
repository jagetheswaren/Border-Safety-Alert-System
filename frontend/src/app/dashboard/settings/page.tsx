"use client";

import React, { useState } from "react";
import {
  Volume2,
  Eye,
  Sliders,
  Check,
} from "lucide-react";

import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { Button } from "@/components/ui/Button";
import { useToast } from "@/components/ui/Toast";

export default function SettingsPage() {
  const { showToast } = useToast();

  const [refreshInterval, setRefreshInterval] = useState("10");
  const [defaultMapType, setDefaultMapType] = useState("roadmap");
  const [audioAlerts, setAudioAlerts] = useState(true);
  const [voiceGuidance, setVoiceGuidance] = useState(true);
  const [vibrationEnabled, setVibrationEnabled] = useState(true);
  const [reducedMotion, setReducedMotion] = useState(false);

  const handleSave = () => {
    localStorage.setItem("bsas_pref_refresh", refreshInterval);
    localStorage.setItem("bsas_pref_map_type", defaultMapType);
    localStorage.setItem("bsas_pref_audio", String(audioAlerts));
    localStorage.setItem("bsas_pref_voice", String(voiceGuidance));
    localStorage.setItem("bsas_pref_reduced_motion", String(reducedMotion));
    showToast("success", "Operator preferences saved successfully.");
  };

  return (
    <div className="flex-1 p-4 sm:p-6 lg:p-8 space-y-6 max-w-5xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-2 border-b border-slate-800/80">
        <div>
          <div className="inline-flex items-center gap-2 text-xs font-semibold text-sky-400 uppercase tracking-wider mb-1">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-400" />
            Operator Preferences
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">
            System Settings
          </h1>
          <p className="text-xs text-slate-400 mt-0.5">
            Configure telemetry polling rate, map presentation defaults, and safety alert notifications
          </p>
        </div>

        <Button
          variant="primary"
          size="sm"
          icon={<Check className="w-4 h-4" />}
          onClick={handleSave}
        >
          Save Changes
        </Button>
      </div>

      <div className="space-y-6">
        {/* Telemetry Polling */}
        <SpotlightCard className="p-6">
          <div className="flex items-center gap-2 text-white mb-3">
            <Sliders className="w-4 h-4 text-sky-400" />
            <h2 className="text-sm font-bold tracking-wide uppercase">
              Telemetry & Refresh Cadence
            </h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div>
              <label className="block text-slate-300 font-semibold mb-1">
                Telemetry Refresh Interval
              </label>
              <select
                value={refreshInterval}
                onChange={(e) => setRefreshInterval(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700/80 text-white rounded-xl px-3 py-2 focus:outline-none focus:border-sky-400"
              >
                <option value="5">Every 5 seconds (High frequency)</option>
                <option value="10">Every 10 seconds (Standard)</option>
                <option value="30">Every 30 seconds (Conserve bandwidth)</option>
                <option value="60">Every 60 seconds (Low rate)</option>
              </select>
              <p className="text-[11px] text-slate-400 mt-1">
                Controls polling frequency for live field units and incidents.
              </p>
            </div>

            <div>
              <label className="block text-slate-300 font-semibold mb-1">
                Default Map Provider & Layer
              </label>
              <select
                value={defaultMapType}
                onChange={(e) => setDefaultMapType(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700/80 text-white rounded-xl px-3 py-2 focus:outline-none focus:border-sky-400"
              >
                <option value="roadmap">Roadmap (Standard tactical)</option>
                <option value="satellite">Satellite (High resolution)</option>
                <option value="hybrid">Hybrid (Satellite + Labels)</option>
                <option value="terrain">Terrain (Topographical contours)</option>
              </select>
              <p className="text-[11px] text-slate-400 mt-1">
                Initial basemap mode loaded when opening the live operations map.
              </p>
            </div>
          </div>
        </SpotlightCard>

        {/* Proximity Warning & Alerts Audio */}
        <SpotlightCard className="p-6">
          <div className="flex items-center gap-2 text-white mb-3">
            <Volume2 className="w-4 h-4 text-amber-400" />
            <h2 className="text-sm font-bold tracking-wide uppercase">
              Audible & Haptic Alerts
            </h2>
          </div>

          <div className="space-y-4 text-xs">
            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800">
              <div>
                <p className="font-semibold text-white">Critical Audible Siren</p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Play urgent warning tone when entering Critical Zone (&lt; 300m).
                </p>
              </div>
              <input
                type="checkbox"
                checked={audioAlerts}
                onChange={(e) => setAudioAlerts(e.target.checked)}
                className="w-4 h-4 accent-sky-500 rounded cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800">
              <div>
                <p className="font-semibold text-white">Text-to-Speech Voice Guidance</p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Audible voice synthesiser announcements for proximity warnings.
                </p>
              </div>
              <input
                type="checkbox"
                checked={voiceGuidance}
                onChange={(e) => setVoiceGuidance(e.target.checked)}
                className="w-4 h-4 accent-sky-500 rounded cursor-pointer"
              />
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800">
              <div>
                <p className="font-semibold text-white">Device Haptic Vibration</p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Vibrate field unit when safety buffer boundary is crossed.
                </p>
              </div>
              <input
                type="checkbox"
                checked={vibrationEnabled}
                onChange={(e) => setVibrationEnabled(e.target.checked)}
                className="w-4 h-4 accent-sky-500 rounded cursor-pointer"
              />
            </div>
          </div>
        </SpotlightCard>

        {/* Accessibility & Visual Motion */}
        <SpotlightCard className="p-6">
          <div className="flex items-center gap-2 text-white mb-3">
            <Eye className="w-4 h-4 text-purple-400" />
            <h2 className="text-sm font-bold tracking-wide uppercase">
              Accessibility & Visual Motion
            </h2>
          </div>

          <div className="flex items-center justify-between p-3 rounded-xl bg-slate-950/60 border border-slate-800 text-xs">
            <div>
              <p className="font-semibold text-white">Prefer Reduced Motion</p>
              <p className="text-[11px] text-slate-400 mt-0.5">
                Disable decorative canvas rendering, radar sweeps, and non-essential transitions.
              </p>
            </div>
            <input
              type="checkbox"
              checked={reducedMotion}
              onChange={(e) => setReducedMotion(e.target.checked)}
              className="w-4 h-4 accent-sky-500 rounded cursor-pointer"
            />
          </div>
        </SpotlightCard>
      </div>
    </div>
  );
}
