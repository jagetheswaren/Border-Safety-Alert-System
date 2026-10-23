"use client";

import React, { useEffect, useState } from "react";
import { isReducedMotion } from "@/lib/motion";

interface CountUpProps {
  to: number;
  from?: number;
  duration?: number;
  className?: string;
  formatter?: (value: number) => string;
}

/**
 * React Bits inspired CountUp:
 * Animated number roll for telemetry metrics.
 */
export const CountUp: React.FC<CountUpProps> = ({
  to,
  from = 0,
  duration = 800,
  className = "",
  formatter,
}) => {
  const [current, setCurrent] = useState(from);

  useEffect(() => {
    if (isReducedMotion()) {
      // Use queueMicrotask to avoid synchronous render update warnings
      queueMicrotask(() => setCurrent(to));
      return;
    }

    let startTimestamp: number | null = null;
    let animationFrameId: number;

    const step = (timestamp: number) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);
      // Ease out cubic
      const ease = 1 - Math.pow(1 - progress, 3);
      const val = Math.round(from + (to - from) * ease);
      setCurrent(val);

      if (progress < 1) {
        animationFrameId = requestAnimationFrame(step);
      }
    };

    animationFrameId = requestAnimationFrame(step);

    return () => {
      cancelAnimationFrame(animationFrameId);
    };
  }, [to, from, duration]);

  const display = formatter ? formatter(current) : current.toLocaleString();

  return <span className={className}>{display}</span>;
};
