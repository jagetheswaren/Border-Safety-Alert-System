"use client";

import React from "react";
import { isReducedMotion } from "@/lib/motion";

interface ShinyTextProps {
  children: React.ReactNode;
  className?: string;
  speed?: number;
}

/**
 * React Bits - ShinyText:
 * Subtle luminous shine sweep across tactical headings and branding badges.
 * Automatically disabled under prefers-reduced-motion.
 */
export const ShinyText: React.FC<ShinyTextProps> = ({
  children,
  className = "",
  speed = 5,
}) => {
  const reduced = isReducedMotion();

  if (reduced) {
    return <span className={className}>{children}</span>;
  }

  return (
    <span
      className={`inline-block bg-[linear-gradient(110deg,#94a3b8,45%,#ffffff,55%,#94a3b8)] bg-[length:200%_100%] bg-clip-text text-transparent ${className}`}
      style={{
        animation: `bsasShinyText ${speed}s ease-in-out infinite`,
      }}
    >
      {children}
    </span>
  );
};
