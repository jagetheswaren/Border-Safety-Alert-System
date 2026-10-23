"use client";

import React from "react";
import { isReducedMotion } from "@/lib/motion";

interface AnimatedListProps {
  children: React.ReactNode;
  staggerMs?: number;
  className?: string;
}

/**
 * React Bits - AnimatedList
 * Staggers children entry animation without re-animating already mounted items.
 * Caps maximum stagger delay to prevent sluggish UI rendering on large lists.
 */
export const AnimatedList: React.FC<AnimatedListProps> = ({
  children,
  staggerMs = 35,
  className = "",
}) => {
  const reduced = isReducedMotion();

  return (
    <div className={className}>
      {React.Children.map(children, (child, index) => {
        if (!React.isValidElement(child)) return child;

        if (reduced) {
          return child;
        }

        const delay = Math.min(index * staggerMs, 280);

        return (
          <div
            style={{
              animation: `bsasFadeInUp 280ms cubic-bezier(0.16, 1, 0.3, 1) ${delay}ms both`,
            }}
          >
            {child}
          </div>
        );
      })}
    </div>
  );
};
