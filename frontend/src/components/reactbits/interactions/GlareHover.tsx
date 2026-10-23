"use client";

import React, { useRef, useState, useCallback } from "react";
import { isReducedMotion } from "@/lib/motion";

interface GlareHoverProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  glareColor?: string;
  className?: string;
}

/**
 * React Bits - GlareHover:
 * Adds a subtle, directional light reflection across cards and primary actions on hover.
 */
export const GlareHover: React.FC<GlareHoverProps> = ({
  children,
  glareColor = "rgba(255, 255, 255, 0.14)",
  className = "",
  ...props
}) => {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [glarePosition, setGlarePosition] = useState({ x: 50, y: 50 });
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseMove = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    if (isReducedMotion() || !containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    setGlarePosition({ x, y });
  }, []);

  const handleMouseEnter = useCallback(() => {
    if (!isReducedMotion()) setIsHovered(true);
  }, []);

  const handleMouseLeave = useCallback(() => {
    setIsHovered(false);
  }, []);

  return (
    <div
      ref={containerRef}
      onMouseMove={handleMouseMove}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className={`relative overflow-hidden group ${className}`}
      {...props}
    >
      {/* Glare Overlay */}
      <div
        className="pointer-events-none absolute inset-0 transition-opacity duration-300 z-20"
        style={{
          opacity: isHovered ? 1 : 0,
          background: `radial-gradient(circle at ${glarePosition.x}% ${glarePosition.y}%, ${glareColor}, transparent 60%)`,
        }}
        aria-hidden="true"
      />
      <div className="relative z-10">{children}</div>
    </div>
  );
};
