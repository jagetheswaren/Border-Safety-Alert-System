"use client";

import React from "react";
import { isReducedMotion } from "@/lib/motion";

interface GridBackgroundProps {
  className?: string;
  cellSize?: number;
  highlightCoordinates?: boolean;
}

/**
 * React Bits - GridBackground
 * Subtle tactical spatial coordinate grid with glowing crosshair nodes.
 * Ideal for Splash, About, 404, and system loading states.
 */
export const GridBackground: React.FC<GridBackgroundProps> = ({
  className = "",
  cellSize = 48,
  highlightCoordinates = true,
}) => {
  const reduced = isReducedMotion();

  return (
    <div
      className={`absolute inset-0 pointer-events-none overflow-hidden ${className}`}
      aria-hidden="true"
    >
      {/* Background SVG Grid Pattern */}
      <svg
        className="absolute inset-0 w-full h-full opacity-20"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <pattern
            id="tactical-grid-pattern"
            width={cellSize}
            height={cellSize}
            patternUnits="userSpaceOnUse"
          >
            <path
              d={`M ${cellSize} 0 L 0 0 0 ${cellSize}`}
              fill="none"
              stroke="rgba(56, 189, 248, 0.4)"
              strokeWidth="0.8"
            />
            <circle
              cx={cellSize}
              cy={cellSize}
              r="1.2"
              fill="rgba(56, 189, 248, 0.7)"
            />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#tactical-grid-pattern)" />
      </svg>

      {/* Radial Vignette Mask */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_20%,var(--bsas-bg)_80%)]" />

      {/* Subtle Scanning Line Animation */}
      {!reduced && (
        <div
          className="absolute inset-x-0 h-[2px] bg-gradient-to-r from-transparent via-sky-400/30 to-transparent opacity-60"
          style={{
            animation: "bsasScanline 8s ease-in-out infinite",
          }}
        />
      )}

      {/* Corner Geospatial Coordinate Watermark */}
      {highlightCoordinates && (
        <div className="absolute bottom-4 right-4 font-mono text-[10px] text-sky-500/40 tracking-widest select-none">
          GRID // WGS84 REF: 09°54&apos;N 78°08&apos;E
        </div>
      )}
    </div>
  );
};
