// BSAS Centralized Motion System & Animation Utilities
// Follows React Bits performance and accessibility best practices

export const motionTokens = {
  duration: {
    fast: 160,
    normal: 280,
    slow: 500,
  },
  easing: {
    outExpo: 'cubic-bezier(0.16, 1, 0.3, 1)',
    outBack: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    inOutQuad: 'cubic-bezier(0.45, 0, 0.55, 1)',
  },
};

/**
 * Checks if the user environment has requested reduced motion.
 */
export function isReducedMotion(): boolean {
  if (typeof window === 'undefined') return false;
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

/**
 * Helper to build inline styles for smooth staggered entrance animations.
 */
export function getStaggerDelay(index: number, baseMs: number = 40): React.CSSProperties {
  if (isReducedMotion()) return {};
  return {
    animationDelay: `${index * baseMs}ms`,
    transitionDelay: `${index * baseMs}ms`,
  };
}
