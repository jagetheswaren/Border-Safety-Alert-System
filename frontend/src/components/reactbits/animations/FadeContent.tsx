"use client";

import React, { useEffect, useState } from "react";
import { isReducedMotion } from "@/lib/motion";

interface FadeContentProps {
  children: React.ReactNode;
  blur?: boolean;
  delay?: number;
  duration?: number;
  className?: string;
}

/**
 * React Bits - FadeContent
 * High-performance opacity fade with optional backdrop blur clearing.
 * Strictly respects prefers-reduced-motion.
 */
export const FadeContent: React.FC<FadeContentProps> = ({
  children,
  blur = false,
  delay = 0,
  duration = 260,
  className = "",
}) => {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(true);
    }, 16);
    return () => clearTimeout(timer);
  }, []);

  const reduced = isReducedMotion();

  if (reduced) {
    return <div className={className}>{children}</div>;
  }

  return (
    <div
      className={className}
      style={{
        opacity: visible ? 1 : 0,
        filter: blur ? (visible ? "blur(0px)" : "blur(4px)") : undefined,
        transitionProperty: blur ? "opacity, filter" : "opacity",
        transitionDuration: `${duration}ms`,
        transitionDelay: `${delay}ms`,
        transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)",
      }}
    >
      {children}
    </div>
  );
};
