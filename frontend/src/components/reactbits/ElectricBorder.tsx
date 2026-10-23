"use client";

import React from "react";

interface ElectricBorderProps {
  children: React.ReactNode;
  className?: string;
  glowColor?: "critical" | "warning" | "cyan";
}

/**
 * React Bits inspired ElectricBorder:
 * Subtle tactical glowing border highlight for critical alerts and active operational modules.
 */
export const ElectricBorder: React.FC<ElectricBorderProps> = ({
  children,
  className = "",
  glowColor = "cyan",
}) => {
  const glowStyles = {
    cyan: "from-sky-500 via-cyan-400 to-blue-600",
    warning: "from-amber-500 via-orange-400 to-yellow-500",
    critical: "from-rose-500 via-red-500 to-rose-700",
  }[glowColor];

  return (
    <div className={`relative p-[1px] rounded-xl overflow-hidden group ${className}`}>
      <div
        className={`absolute -inset-[100%] animate-[spin_8s_linear_infinite] bg-[conic-gradient(from_0deg,transparent_0_340deg,var(--tw-gradient-stops))] ${glowStyles} opacity-80`}
        aria-hidden="true"
      />
      <div className="relative rounded-[11px] bg-slate-900 overflow-hidden">
        {children}
      </div>
    </div>
  );
};
