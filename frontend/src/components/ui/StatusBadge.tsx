"use client";

import React from "react";
import { Shield, AlertTriangle, AlertCircle, CheckCircle2, Wifi, WifiOff } from "lucide-react";

export type StatusLevel =
  | "SAFE"
  | "AWARENESS"
  | "WARNING"
  | "CRITICAL"
  | "ONLINE"
  | "OFFLINE"
  | "DEGRADED"
  | "OPEN"
  | "ACKNOWLEDGED"
  | "RESOLVED";

interface StatusBadgeProps {
  status: StatusLevel | string;
  showIcon?: boolean;
  className?: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status,
  showIcon = true,
  className = "",
}) => {
  const norm = status?.toUpperCase() || "UNKNOWN";

  const config = (() => {
    switch (norm) {
      case "SAFE":
      case "RESOLVED":
        return {
          bg: "bg-emerald-950/70 border-emerald-800/80 text-emerald-300",
          dot: "bg-emerald-500",
          icon: <CheckCircle2 className="w-3 h-3 text-emerald-400" />,
        };
      case "AWARENESS":
      case "ACKNOWLEDGED":
        return {
          bg: "bg-sky-950/70 border-sky-800/80 text-sky-300",
          dot: "bg-sky-400",
          icon: <Shield className="w-3 h-3 text-sky-400" />,
        };
      case "WARNING":
      case "DEGRADED":
        return {
          bg: "bg-amber-950/70 border-amber-800/80 text-amber-300",
          dot: "bg-amber-400",
          icon: <AlertTriangle className="w-3 h-3 text-amber-400" />,
        };
      case "CRITICAL":
      case "OPEN":
        return {
          bg: "bg-rose-950/80 border-rose-800 text-rose-300",
          dot: "bg-rose-500 animate-pulse",
          icon: <AlertCircle className="w-3 h-3 text-rose-400" />,
        };
      case "ONLINE":
        return {
          bg: "bg-emerald-950/70 border-emerald-800 text-emerald-300",
          dot: "bg-emerald-500 animate-pulse",
          icon: <Wifi className="w-3 h-3 text-emerald-400" />,
        };
      case "OFFLINE":
        return {
          bg: "bg-slate-900 border-slate-700 text-slate-400",
          dot: "bg-slate-500",
          icon: <WifiOff className="w-3 h-3 text-slate-500" />,
        };
      default:
        return {
          bg: "bg-slate-900 border-slate-800 text-slate-400",
          dot: "bg-slate-500",
          icon: null,
        };
    }
  })();

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full border text-[11px] font-semibold tracking-wide uppercase select-none ${config.bg} ${className}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${config.dot}`} aria-hidden="true" />
      {showIcon && config.icon}
      <span>{norm}</span>
    </span>
  );
};
