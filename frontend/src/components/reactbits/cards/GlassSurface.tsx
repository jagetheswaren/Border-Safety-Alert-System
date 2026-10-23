"use client";

import React from "react";

interface GlassSurfaceProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  blurLevel?: "sm" | "md" | "lg";
  className?: string;
}

/**
 * React Bits - GlassSurface
 * High-legibility tactical dark glass surface with border glow.
 * Optimized specifically for floating map controls, search inputs, and overlay panels.
 */
export const GlassSurface: React.FC<GlassSurfaceProps> = ({
  children,
  blurLevel = "md",
  className = "",
  ...props
}) => {
  const blurClass = {
    sm: "backdrop-blur-sm bg-slate-900/75 border-slate-700/50",
    md: "backdrop-blur-md bg-slate-900/85 border-slate-700/60 shadow-xl shadow-black/40",
    lg: "backdrop-blur-lg bg-slate-900/92 border-slate-700/80 shadow-2xl shadow-black/60",
  }[blurLevel];

  return (
    <div
      className={`border rounded-xl text-slate-100 transition-colors ${blurClass} ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};
