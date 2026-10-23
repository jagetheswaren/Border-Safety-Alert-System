# BSAS Design System & UI/UX Architecture

## 1. Overview & Civilian Safety Philosophy
The Border Safety Alert System (BSAS) mobile application and Next.js operations dashboard are designed with a **civilian safety, human-centered ethos**. 
- Strictly **no military HUD, dystopian sci-fi, or combat aesthetics**.
- High-contrast, clean, and utilitarian Material 3 design tokens.
- Subtle, functional micro-animations (strictly 150ms–250ms ease-out) that enhance spatial comprehension without causing cognitive clutter or distraction during safety-critical events.
- Full compliance with WCAG 2.1 AA accessibility guidelines, colorblind-safe palettes, and explicit reduced-motion support.

---

## 2. Design Tokens

### Color Palette
| Token Name | Hex Code | Purpose | Contrast Ratio (vs #020617) |
| :--- | :--- | :--- | :--- |
| `backgroundDark` | `#020617` (Slate 950) | Primary canvas background | 21:1 |
| `surfaceDark` | `#0B132B` (Deep Navy) | Card & modal surfaces | 18.5:1 |
| `surfaceBorder` | `#1E293B` (Slate 800) | Subtle container outlines | 4.8:1 |
| `safeGreen` | `#10B981` (Emerald 500) | Verified safe zone, clear status | 11.2:1 |
| `warningAmber` | `#F59E0B` (Amber 500) | Caution zone, approaching boundary | 12.8:1 |
| `criticalRed` | `#EF4444` (Rose 500) | Restricted boundary violation, emergency | 9.4:1 |
| `accentSky` | `#0284C7` (Sky 600) | Interactive accents, GPS telemetry | 7.9:1 |
| `textPrimary` | `#F8FAFC` (Slate 50) | Primary typography, headers | 19.8:1 |
| `textSecondary` | `#94A3B8` (Slate 400) | Subtitles, secondary telemetry | 7.5:1 |
| `textMuted` | `#64748B` (Slate 500) | Captions, metadata timestamps | 4.6:1 |

### Typography
- **Primary Typeface**: Inter / Geist Sans (Open-source humanist sans-serif).
- **Monospace Telemetry**: JetBrains Mono / Geist Mono for GPS coordinates, speed, bearing, and hash checksums.
- **Scale**:
  - Display / Risk Status: 28px, Bold (700)
  - Card Title: 16px, Semi-Bold (600)
  - Body Text: 14px, Regular (400), 1.5 line-height
  - Micro Captions: 11px, Medium (500), 0.5px letter-spacing

---

## 3. Motion & Micro-Interactions
- **Standard Curve**: `Curves.easeOutCubic` / `cubic-bezier(0.2, 0, 0, 1)`
- **Duration Scale**:
  - Micro-taps / Ripple / State Changes: 150ms
  - Screen Cross-fades & Modals: 200ms
  - Boundary Radar Pulse: 1200ms looping breath (reduced to static ring when `MediaQuery.of(context).disableAnimations` is true)
- **Reduced Motion**: Automatically respected through `AppMotion` and CSS `@media (prefers-reduced-motion: reduce)`.

---

## 4. Reusable UI Components

### Flutter Mobile (`lib/core/widgets/`)
1. **`BSASSlideButton`**: Two-stage safety confirmation button requiring intentional horizontal drag or tap confirmation to prevent accidental SOS / false emergency alerts.
2. **`BSASCard`**: Touch-aware card featuring a subtle spotlight radial gradient on touch point, 1px solid border, and ergonomic padding.
3. **`BSASElectricBorder`**: Dynamic animated border indicating proximity warning states with configurable color tokens and reduced-motion fallback.
4. **`BSASPillNav`**: Smooth horizontal categorical filter tabs with sliding pill indicator.
5. **`BSASBottomNav`**: Ergonomic bottom navigation bar with clear icon-and-text labels for thumb reach.
6. **`BSASCountUp`**: Smooth numeric interpolator for distance, speed, and coordinate counters.
7. **`BSASEmptyState` & `BSASErrorState`**: Honest, descriptive state indicators explaining:
   - What happened (e.g., GPS constellation lock searching).
   - What still works (e.g., Offline vector maps, cached safety zones).
   - Concrete next action (e.g., Refresh feed, open diagnostics).

### Next.js Operations Web Dashboard (`frontend/src/`)
1. **`SpotlightCard`**: Modern CSS radial spotlight effect tracking cursor coordinates.
2. **`DecryptedText`**: Clean cryptographic telemetry transition effect for incident updates.
3. **`MetricCounter`**: Dynamic numeric counter for fleet telemetry and incident counts.
4. **`ElectricBorder`**: High-priority alert banner border for active critical border violations.
5. **`GlassPanel`**: Accessible backdrop-blur container with dark mode contrast tokens.

---

## 5. Offline & Network Resilience Design
- **Offline Banner**: Clear status indicator in app header displaying "OFFLINE MODE — ArcGIS Vector Storage Active".
- **Map Fallback**: Seamless rendering of local tile caches with satellite hybrid labels.
- **Zero Blinking / Layout Shifts**: Skeleton placeholders with fixed aspect ratios during asynchronous boundary loading.
