// BSAS Unified Operational Design Tokens
// Modern tactical geospatial design system

export const designTokens = {
  colors: {
    bg: '#090d16',
    surface: '#0f172a',
    surfaceElevated: '#1e293b',
    surfaceHover: '#334155',
    border: '#334155',
    borderSubtle: 'rgba(51, 65, 85, 0.5)',
    borderActive: '#38bdf8',

    text: '#f8fafc',
    textMuted: '#94a3b8',
    textDim: '#64748b',

    accent: '#0284c7',
    accentLight: '#38bdf8',
    accentDark: '#0369a1',
    accentGlow: 'rgba(2, 132, 199, 0.25)',

    // Semantic Status Colors (Preserved across all layers)
    status: {
      safe: '#10b981',        // Emerald green
      awareness: '#38bdf8',   // Tactical sky blue
      warning: '#f59e0b',     // Amber
      critical: '#ef4444',    // Urgent crimson
      online: '#10b981',
      degraded: '#f59e0b',
      offline: '#94a3b8',
    },
  },

  typography: {
    fontSans: 'var(--font-geist-sans), -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    fontMono: 'var(--font-geist-mono), "JetBrains Mono", Consolas, monospace',
  },

  motion: {
    durations: {
      fast: 140,
      normal: 260,
      slow: 450,
    },
    easings: {
      default: 'cubic-bezier(0.16, 1, 0.3, 1)',
      easeOut: 'cubic-bezier(0, 0, 0.2, 1)',
      easeInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
      bounce: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    },
  },

  spacing: {
    sidebarExpanded: '250px',
    sidebarCollapsed: '74px',
    topbarHeight: '56px',
    bottomNavHeight: '64px',
  },

  zIndex: {
    map: 1,
    mapControls: 10,
    mapOverlays: 20,
    dock: 30,
    sidebar: 40,
    topbar: 45,
    drawer: 50,
    modal: 60,
    toast: 70,
    commandPalette: 80,
  },
} as const;

export type DesignTokens = typeof designTokens;
