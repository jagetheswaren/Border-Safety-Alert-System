"use client";

import React, { useRef, useState, useCallback } from "react";
import { isReducedMotion } from "@/lib/motion";

interface MagnetProps {
  children: React.ReactElement;
  strength?: number;
  className?: string;
}

/**
 * React Bits inspired Magnet:
 * Attracts interactive buttons subtly toward cursor on proximity/hover.
 */
export const Magnet: React.FC<MagnetProps> = ({
  children,
  strength = 12,
  className = "",
}) => {
  const ref = useRef<HTMLDivElement | null>(null);
  const [offset, setOffset] = useState({ x: 0, y: 0 });

  const handleMouseMove = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (isReducedMotion() || !ref.current) return;
      const { left, top, width, height } = ref.current.getBoundingClientRect();
      const centerX = left + width / 2;
      const centerY = top + height / 2;
      const distanceX = e.clientX - centerX;
      const distanceY = e.clientY - centerY;

      setOffset({
        x: (distanceX / (width / 2)) * strength,
        y: (distanceY / (height / 2)) * strength,
      });
    },
    [strength]
  );

  const handleMouseLeave = useCallback(() => {
    setOffset({ x: 0, y: 0 });
  }, []);

  return (
    <div
      ref={ref}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className={`inline-block transition-transform duration-200 ease-out ${className}`}
      style={{
        transform: `translate3d(${offset.x}px, ${offset.y}px, 0)`,
      }}
    >
      {children}
    </div>
  );
};
