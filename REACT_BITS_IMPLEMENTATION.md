# BSAS — React Bits Implementation Guide & Technical Specification

This document provides technical documentation for all BSAS-adapted React Bits components integrated across the Border Safety & Alert System (BSAS) frontend application (`frontend/src/components/reactbits/`).

---

## 1. Component Registry & Technical Specs

### 1. Cubes (`backgrounds/Cubes.tsx`)
- **React Bits Concept**: 3D Isometric spatial grid animation.
- **BSAS Component**: `<Cubes />`
- **Target Page(s)**: `/login`, Splash / Preloader.
- **Purpose**: Creates an atmospheric geospatial spatial canvas representing monitored terrain grids without loading WebGL/Three.js engines.
- **Dependencies**: None (Native HTML5 2D Canvas).
- **Performance Notes**: Pauses animation when browser tab is inactive or blurred; strictly unmounted when navigating to the Live Map canvas.
- **Mobile Behavior**: Grid size automatically scales down to maintain 60 FPS on mobile chips.
- **Reduced-Motion Behavior**: Disables sine wave elevation transforms; renders a clean, static isometric wireframe.

---

### 2. GridBackground (`backgrounds/GridBackground.tsx`)
- **React Bits Concept**: Subtle technical coordinate grid background.
- **BSAS Component**: `<GridBackground />`
- **Target Page(s)**: `/about`, `/404`, `/403`, `/dev/ui-showcase`.
- **Purpose**: Adds tactical military/GIS grid lines with pulsing coordinate node markers.
- **Dependencies**: None (SVG pattern + CSS keyframe).
- **Performance Notes**: Hardware-accelerated SVG pattern rasterized once by the browser.
- **Mobile Behavior**: Responsive; coordinate watermark hidden on narrow viewports.
- **Reduced-Motion Behavior**: Scanline keyframe animation disabled.

---

### 3. SpotlightCard (`cards/SpotlightCard.tsx`)
- **React Bits Concept**: Radial illumination following mouse pointer.
- **BSAS Component**: `<SpotlightCard />`
- **Target Page(s)**: `/dashboard`, `/dashboard/devices`, `/dashboard/health`, `/dashboard/boundaries`, `/dashboard/analytics`.
- **Purpose**: Elevates telemetry metrics and incident cards with an ambient tactical glow without causing layout reflow.
- **Dependencies**: None.
- **Performance Notes**: Uses passive pointer move calculations throttled via `useCallback`.
- **Mobile Behavior**: Spotlight opacity remains zero; card retains standard tactile active highlight.
- **Reduced-Motion Behavior**: Spotlight disabled; static high-contrast border state rendered.

---

### 4. ElectricBorder (`cards/ElectricBorder.tsx`)
- **React Bits Concept**: Dynamic rotating glowing gradient perimeter.
- **BSAS Component**: `<ElectricBorder />`
- **Target Page(s)**: `/dashboard/alerts` (Exclusively for Critical proximity incursions &lt; 300m).
- **Purpose**: Urgent visual alert state for critical border safety events.
- **Dependencies**: None (CSS `conic-gradient` spin).
- **Performance Notes**: GPU composited transform rotation; applied strictly to active emergency items (never to entire pages).
- **Mobile Behavior**: Fully rendered on all mobile screen sizes.
- **Reduced-Motion Behavior**: Rotation paused; displays a solid, high-visibility red perimeter.

---

### 5. GlassSurface (`cards/GlassSurface.tsx`)
- **React Bits Concept**: Frosted glass surface overlay.
- **BSAS Component**: `<GlassSurface />`
- **Target Page(s)**: `/dashboard/map` (Floating search, Dock, Route Planner, Legend).
- **Purpose**: Floats operational controls directly over live Google Maps / MapLibre basemaps while maintaining WCAG AA contrast.
- **Dependencies**: None (Tailwind CSS backdrop blur + border).
- **Performance Notes**: GPU hardware-accelerated compositing layer.
- **Mobile Behavior**: Snaps to bottom sheet or full-width floating header on screens &lt; 768px.
- **Reduced-Motion Behavior**: Preserves glass appearance without transitional effects.

---

### 6. Dock & DockItem (`navigation/Dock.tsx`)
- **React Bits Concept**: Mac-style floating dock with icon magnification and tooltips.
- **BSAS Component**: `<Dock>`, `<DockItem>`
- **Target Page(s)**: `/dashboard/map`, `/dev/ui-showcase`.
- **Purpose**: Groups primary map operations (Locate, Route, Street View, Traffic, Layers, Fullscreen) in a compact, floating dock.
- **Dependencies**: `lucide-react`.
- **Performance Notes**: Transforms use `scale` and `translate3d`, avoiding geometry reflow.
- **Mobile Behavior**: Renders horizontally docked above the mobile navigation bar.
- **Reduced-Motion Behavior**: Icon magnification on hover disabled; tooltips appear instantly.

---

### 7. PillNav (`navigation/PillNav.tsx`)
- **React Bits Concept**: Pill-shaped tab navigation with sliding active background.
- **BSAS Component**: `<PillNav />`
- **Target Page(s)**: `/dashboard/incidents`, `/dashboard/alerts`, Map Basemap Mode switch (Road / Sat / Terr).
- **Purpose**: Tactile filtering and mode switching.
- **Dependencies**: None.
- **Performance Notes**: Fast CSS transition (150ms `cubic-bezier(0.16, 1, 0.3, 1)`).
- **Mobile Behavior**: Horizontally scrollable on small mobile displays.
- **Reduced-Motion Behavior**: Background switches immediately without slide transition.

---

### 8. DecryptedText (`text/DecryptedText.tsx`)
- **React Bits Concept**: Progressive cyber-character scramble decode.
- **BSAS Component**: `<DecryptedText />`
- **Target Page(s)**: `/login` (Brand title), `/about`, `/dev/ui-showcase`.
- **Purpose**: Adds high-end tactical system authentication branding.
- **Dependencies**: None.
- **Performance Notes**: Self-terminating interval timer; cleans up listeners immediately upon sequence completion.
- **Mobile Behavior**: Runs identically on mobile.
- **Reduced-Motion Behavior**: Displays final decoded string immediately without animation.

---

### 9. ShinyText (`text/ShinyText.tsx`)
- **React Bits Concept**: Luminous light sweep passing across text.
- **BSAS Component**: `<ShinyText />`
- **Target Page(s)**: Header system status badges, operational status chips.
- **Purpose**: Conveys live system readiness and operational status.
- **Dependencies**: None (CSS background clip keyframe).
- **Performance Notes**: Completely hardware-accelerated.
- **Mobile Behavior**: Fully supported.
- **Reduced-Motion Behavior**: Animation disabled; displays static white/slate text.

---

### 10. CountUp (`text/CountUp.tsx`)
- **React Bits Concept**: Rolling numeric telemetry counter.
- **BSAS Component**: `<CountUp />`
- **Target Page(s)**: `/dashboard` (Telemetry counters), `/dashboard/analytics`, Route Planner (Distance, ETA).
- **Purpose**: Animates live data arrival without jarring layout shifts.
- **Dependencies**: None (`requestAnimationFrame` with cubic ease-out curve).
- **Performance Notes**: Terminates after 800ms; does not re-animate unless target value changes.
- **Mobile Behavior**: Fully supported.
- **Reduced-Motion Behavior**: Immediately outputs final numeric string.

---

### 11. Magnet (`interactions/Magnet.tsx`)
- **React Bits Concept**: Cursor attraction physics on proximity.
- **BSAS Component**: `<Magnet />`
- **Target Page(s)**: Primary CTA buttons, Login Sign-In button (`BSASMagneticButton`).
- **Purpose**: Tactile attraction for key operator actions.
- **Dependencies**: None.
- **Performance Notes**: Operates within a bounded 12px bounding box using `translate3d`.
- **Mobile Behavior**: Automatically bypassed on touch-based devices.
- **Reduced-Motion Behavior**: Transform locked to `(0, 0)`.

---

### 12. GlareHover (`interactions/GlareHover.tsx`)
- **React Bits Concept**: Directional light reflection sweep on hover.
- **BSAS Component**: `<GlareHover />`
- **Target Page(s)**: Operational cards, secondary CTAs.
- **Purpose**: Gives cards a glass-like sheen as the cursor moves over them.
- **Dependencies**: None.
- **Performance Notes**: Radial gradient rendered inside an absolute overlay with `pointer-events-none`.
- **Mobile Behavior**: Ignored on touch devices.
- **Reduced-Motion Behavior**: Glare overlay hidden.

---

### 13. SlideButton (`interactions/SlideButton.tsx`)
- **React Bits Concept**: Horizontal fill slide button with state morphing.
- **BSAS Component**: `<SlideButton />`, `<BSASSlideButton />`
- **Target Page(s)**: Login submit, Offline sync trigger, Route calculation, Map actions.
- **Purpose**: Replaces conventional click buttons with tactile progress feedback (idle → loading → confirmed).
- **Dependencies**: `lucide-react`.
- **Performance Notes**: Smooth 200ms transform fill with micro-scale compression.
- **Mobile Behavior**: Full touch responsiveness with active feedback.
- **Reduced-Motion Behavior**: Background fill appears instantly without sliding transition.

---

### 14. AnimatedContent (`animations/AnimatedContent.tsx`)
- **React Bits Concept**: Staggered fade and slide content entry.
- **BSAS Component**: `<AnimatedContent />`
- **Target Page(s)**: Global container for all authenticated views.
- **Purpose**: Eliminates jarring page switches during client-side navigation.
- **Dependencies**: None.
- **Performance Notes**: Executes once on mount (320ms `cubic-bezier(0.16, 1, 0.3, 1)`).
- **Mobile Behavior**: Universal compatibility.
- **Reduced-Motion Behavior**: Content mounts at full opacity without translation.

---

### 15. FadeContent (`animations/FadeContent.tsx`)
- **React Bits Concept**: High-performance opacity fade with optional blur clearing.
- **BSAS Component**: `<FadeContent />`
- **Target Page(s)**: Drawer panels, Route Planner side sheet, Street View split view.
- **Purpose**: Smooth panel transitions without layout shifts.
- **Dependencies**: None.
- **Performance Notes**: Hardware-accelerated opacity transition.
- **Mobile Behavior**: Universal compatibility.
- **Reduced-Motion Behavior**: Instant appearance.

---

### 16. ScrollReveal (`animations/ScrollReveal.tsx`)
- **React Bits Concept**: Passive scroll-triggered entry animation.
- **BSAS Component**: `<ScrollReveal />`
- **Target Page(s)**: `/dashboard/analytics`, `/about`, `/dev/ui-showcase`.
- **Purpose**: Reveals secondary charts and sections as the operator scrolls down.
- **Dependencies**: None (Native `IntersectionObserver`).
- **Performance Notes**: Disconnects observer once revealed; zero scroll event polling.
- **Mobile Behavior**: Universal compatibility.
- **Reduced-Motion Behavior**: Elements initialized in revealed state immediately.

---

### 17. AnimatedList (`animations/AnimatedList.tsx`)
- **React Bits Concept**: Staggered entry for dynamic data lists.
- **BSAS Component**: `<AnimatedList />`
- **Target Page(s)**: `/dashboard/incidents`, `/dashboard/alerts`, `/dashboard/events`.
- **Purpose**: Staggers incoming real-time telemetry items without re-animating already mounted list rows.
- **Dependencies**: None.
- **Performance Notes**: Delays are capped at 280ms total to ensure immediate legibility.
- **Mobile Behavior**: Universal compatibility.
- **Reduced-Motion Behavior**: Stagger bypassed; all items display simultaneously.

---

## 2. Button System Mapping (`components/ui/BSASButtons.tsx`)

| BSAS Button Component | Base Technology | Interaction Highlights |
| :--- | :--- | :--- |
| `BSASPrimaryButton` | `Button.tsx` | Sky-600 background, micro-scale on click, shadow-sky-600/30 |
| `BSASSecondaryButton` | `Button.tsx` | Slate-800 background, border-slate-700/80, subtle hover brighten |
| `BSASGhostButton` | `Button.tsx` | Transparent base, slate-800 hover fill, clean typography |
| `BSASDangerButton` | `Button.tsx` | Rose-600 background, shadow-rose-600/30, reserved for session termination |
| `BSASIconButton` | `IconButton.tsx` | 40x40px touch target, centered SVG icon, focus-visible ring |
| `BSASSlideButton` | `SlideButton.tsx` | Left-to-right accent fill on hover, loading spinner, success check morph |
| `BSASMagneticButton` | `Magnet.tsx` | Cursor tracking attraction for high-value operational CTAs |

---

## 3. Directory Layout

```text
frontend/src/components/
├── reactbits/
│   ├── animations/
│   │   ├── AnimatedContent.tsx
│   │   ├── AnimatedList.tsx
│   │   ├── FadeContent.tsx
│   │   └── ScrollReveal.tsx
│   ├── backgrounds/
│   │   ├── Cubes.tsx
│   │   └── GridBackground.tsx
│   ├── cards/
│   │   ├── ElectricBorder.tsx
│   │   ├── GlassSurface.tsx
│   │   └── SpotlightCard.tsx
│   ├── interactions/
│   │   ├── GlareHover.tsx
│   │   ├── Magnet.tsx
│   │   └── SlideButton.tsx
│   ├── navigation/
│   │   ├── Dock.tsx
│   │   └── PillNav.tsx
│   ├── text/
│   │   ├── CountUp.tsx
│   │   ├── DecryptedText.tsx
│   │   └── ShinyText.tsx
│   └── index.ts
└── ui/
    ├── BSASButtons.tsx
    ├── BottomSheet.tsx
    ├── Button.tsx
    ├── Drawer.tsx
    ├── EmptyState.tsx
    ├── GlassPanel.tsx
    ├── IconButton.tsx
    ├── LoadingState.tsx
    ├── MetricCard.tsx
    ├── SlideActionButton.tsx
    ├── StatusBadge.tsx
    ├── Toast.tsx
    └── Tooltip.tsx
```
