"use client";

import React, { useEffect, useState } from "react";
import { isReducedMotion } from "@/lib/motion";

interface AnimatedContentProps {
  children: React.ReactNode;
  distance?: number;
  direction?: "vertical" | "horizontal";
  reverse?: boolean;
  delay?: number;
  duration?: number;
  className?: string;
}

/**
 * React Bits inspired AnimatedContent:
 * Smoothly reveals and elevates content on entry.
 */
export const AnimatedContent: React.FC<AnimatedContentProps> = ({
  children,
  distance = 16,
  direction = "vertical",
  reverse = false,
  delay = 0,
  duration = 320,
  className = "",
}) => {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    // Delay mounting transition to ensure browser paint
    const timer = setTimeout(() => {
      setMounted(true);
    }, 16);
    return () => clearTimeout(timer);
  }, []);

  const reduced = isReducedMotion();

  if (reduced) {
    return <div className={className}>{children}</div>;
  }

  const offset = reverse ? -distance : distance;
  const transform = mounted
    ? "translate3d(0, 0, 0)"
    : direction === "vertical"
    ? `translate3d(0, ${offset}px, 0)`
    : `translate3d(${offset}px, 0, 0)`;

  return (
    <div
      className={className}
      style={{
        opacity: mounted ? 1 : 0,
        transform,
        transitionProperty: "opacity, transform",
        transitionDuration: `${duration}ms`,
        transitionDelay: `${delay}ms`,
        transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)",
      }}
    >
      {children}
    </div>
  );
};
