"use client";

import React from "react";

interface PillOption<T extends string> {
  id: T;
  label: string;
  badge?: number | string;
  icon?: React.ReactNode;
}

interface PillNavProps<T extends string> {
  options: PillOption<T>[];
  value: T;
  onChange: (value: T) => void;
  className?: string;
  size?: "sm" | "md";
}

/**
 * React Bits inspired PillNav:
 * Tactile pill navigation with sliding active state for map modes, filters, and status switches.
 */
export function PillNav<T extends string>({
  options,
  value,
  onChange,
  className = "",
  size = "md",
}: PillNavProps<T>) {
  return (
    <div
      className={`inline-flex items-center p-1 rounded-xl bg-slate-900 border border-slate-800 shadow-inner ${className}`}
      role="tablist"
    >
      {options.map((opt) => {
        const isActive = opt.id === value;
        return (
          <button
            key={opt.id}
            type="button"
            role="tab"
            aria-selected={isActive}
            onClick={() => onChange(opt.id)}
            className={`relative flex items-center justify-center gap-1.5 rounded-lg font-medium transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 ${
              size === "sm" ? "px-2.5 py-1 text-xs" : "px-3.5 py-1.5 text-xs"
            } ${
              isActive
                ? "bg-sky-600 text-white shadow-md shadow-sky-600/30 font-semibold"
                : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50"
            }`}
          >
            {opt.icon && <span className="shrink-0">{opt.icon}</span>}
            <span>{opt.label}</span>
            {opt.badge !== undefined && (
              <span
                className={`ml-1 px-1.5 py-0.2 rounded-full text-[10px] font-bold ${
                  isActive
                    ? "bg-sky-700/80 text-white"
                    : "bg-slate-800 text-slate-400"
                }`}
              >
                {opt.badge}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
