"use client";

import React, { useEffect, useRef, useState } from "react";
import { isReducedMotion } from "@/lib/motion";

interface ScrollRevealProps {
  children: React.ReactNode;
  threshold?: number;
  distance?: number;
  duration?: number;
  className?: string;
}

/**
 * React Bits - ScrollReveal
 * Triggers a tactical entry animation once when the element scrolls into the viewport.
 * Uses passive IntersectionObserver without polling or heavy scroll listeners.
 */
export const ScrollReveal: React.FC<ScrollRevealProps> = ({
  children,
  threshold = 0.15,
  distance = 20,
  duration = 380,
  className = "",
}) => {
  const [revealed, setRevealed] = useState(false);
  const elementRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isReducedMotion()) {
      queueMicrotask(() => setRevealed(true));
      return;
    }

    const current = elementRef.current;
    if (!current) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setRevealed(true);
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold }
    );

    observer.observe(current);

    return () => {
      observer.disconnect();
    };
  }, [threshold]);

  const reduced = isReducedMotion();

  if (reduced) {
    return <div className={className}>{children}</div>;
  }

  return (
    <div
      ref={elementRef}
      className={className}
      style={{
        opacity: revealed ? 1 : 0,
        transform: revealed ? "translate3d(0, 0, 0)" : `translate3d(0, ${distance}px, 0)`,
        transitionProperty: "opacity, transform",
        transitionDuration: `${duration}ms`,
        transitionTimingFunction: "cubic-bezier(0.16, 1, 0.3, 1)",
      }}
    >
      {children}
    </div>
  );
};
