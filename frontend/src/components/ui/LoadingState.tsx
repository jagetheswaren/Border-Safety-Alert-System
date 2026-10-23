"use client";

import React from "react";
import { Shield } from "lucide-react";

interface LoadingStateProps {
  label?: string;
  variant?: "fullscreen" | "card" | "inline";
  className?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({
  label = "Initializing tactical telemetry...",
  variant = "card",
  className = "",
}) => {
  if (variant === "fullscreen") {
    return (
      <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-slate-950 text-slate-100 p-6">
        <div className="relative flex items-center justify-center mb-6">
          <div className="w-16 h-16 rounded-full border-2 border-sky-500/20 border-t-sky-400 animate-spin" />
          <Shield className="w-7 h-7 text-sky-400 absolute" />
        </div>
        <p className="text-xs font-semibold tracking-wider uppercase text-sky-400">
          BSAS · Operations Center
        </p>
        <p className="text-xs text-slate-400 mt-2 tracking-wide animate-pulse">
          {label}
        </p>
      </div>
    );
  }

  return (
    <div
      className={`flex flex-col items-center justify-center p-8 text-center rounded-2xl border border-slate-800 bg-slate-900/40 ${className}`}
    >
      <div className="w-8 h-8 rounded-full border-2 border-sky-500/30 border-t-sky-400 animate-spin mb-3" />
      <p className="text-xs text-slate-400 animate-pulse">{label}</p>
    </div>
  );
};
