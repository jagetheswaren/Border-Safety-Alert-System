"use client";

import React from "react";
import { SpotlightCard } from "@/components/reactbits/SpotlightCard";
import { CountUp } from "@/components/reactbits/CountUp";

interface MetricCardProps {
  title: string;
  value: number | string;
  icon: React.ReactNode;
  subtitle?: string;
  change?: string;
  trend?: "up" | "down" | "neutral";
  color?: string;
  className?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  title,
  value,
  icon,
  subtitle,
  change,
  trend = "neutral",
  color = "text-sky-400",
  className = "",
}) => {
  const isNumeric = typeof value === "number";

  return (
    <SpotlightCard className={`p-5 flex flex-col justify-between ${className}`}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-semibold tracking-wider uppercase text-slate-400">
            {title}
          </p>
          <div className={`mt-2 text-2xl font-bold tracking-tight ${color}`}>
            {isNumeric ? <CountUp to={value as number} /> : value}
          </div>
        </div>
        <div className="p-2.5 rounded-xl bg-slate-800/80 border border-slate-700/60 shrink-0">
          {icon}
        </div>
      </div>

      {(subtitle || change) && (
        <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
          {subtitle && <span>{subtitle}</span>}
          {change && (
            <span
              className={`font-medium ${
                trend === "up"
                  ? "text-emerald-400"
                  : trend === "down"
                  ? "text-rose-400"
                  : "text-slate-400"
              }`}
            >
              {change}
            </span>
          )}
        </div>
      )}
    </SpotlightCard>
  );
};
