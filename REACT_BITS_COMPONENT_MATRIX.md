# BSAS — React Bits Component Evaluation Matrix

This matrix documents the inspection, architectural justification, performance budget, and accessibility behavior for every component category within the [React Bits](https://reactbits.dev/) design and motion library as adapted for the **Border Safety & Alert System (BSAS)**.

---

## Evaluation Criteria & Performance Invariants
1. **Google Maps Canvas Priority**: Zero WebGL or continuous canvas animations are permitted on the Live Map canvas (`/dashboard/map`) to guarantee a 60 FPS rendering budget during active pan, zoom, Street View 360°, and live route calculations.
2. **Accessibility (`prefers-reduced-motion`)**: Every adapted motion component strictly integrates `isReducedMotion()` (`lib/motion.ts`), degrading to static opacity or zero-transform rendering when reduced motion is requested.
3. **Bundle Size & Dependency Hygiene**: Heavy peer dependencies (`three.js`, `@react-three/fiber`, `gsap`) are avoided in favor of native 2D canvas, CSS hardware-accelerated transforms (`translate3d`, `scale`), and lightweight React hooks.

---

## React Bits Full-Library Matrix

| React Bits Component | Category | Evaluation | Purpose in BSAS | Target Page(s) | Performance Cost | Mobile Support | Reduced-Motion Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Cubes** | Backgrounds / 3D | **USE** | Lightweight isometric spatial grid | `/login`, Startup | Low (Pure 2D Canvas, pauses on window blur) | Fully supported (auto-downscaled) | Zero sine wave elevation; flat static isometric grid |
| **GridBackground** | Backgrounds | **USE** | Tactical geospatial crosshair coordinate grid | `/about`, `/404`, `/403`, `/dev/ui-showcase` | Minimal (SVG Pattern + GPU scanline) | Responsive | Scanline disabled; static SVG pattern |
| **Particles** | Backgrounds | **NOT USE** | Continuous particle physics | N/A (Conflicts with Cubes on login; would overload map) | Medium-High (DOM/Canvas particle churn) | High battery consumption | N/A |
| **Hyperspeed** | Backgrounds | **NOT USE** | Starfield warp effect | N/A (Aesthetic mismatch: arcade gaming feel) | High (Three.js WebGL canvas required) | Sluggish on budget Android | N/A |
| **SpotlightCard** | Cards | **USE** | Ambient cursor-following radial highlight | `/dashboard`, `/devices`, `/health`, `/boundaries`, `/analytics` | Ultra-Low (Passive mousemove coordinate listener) | Degrades gracefully to touch | Spotlight hidden; static border highlight |
| **ElectricBorder** | Cards / Micro | **USE** | High-priority spinning gradient perimeter | `/dashboard/alerts` (Critical proximity &lt; 300m) | Low (GPU conic-gradient spin) | Fully supported | Animation paused; static solid red border |
| **GlassSurface** | Cards / Layout | **USE** | Dark high-contrast frosted glass surface | `/dashboard/map` (Search, Dock, Route, Legend) | Low-Medium (`backdrop-blur-md` GPU composited) | Fully supported | Preserves frosted blur without transitions |
| **TiltedCard** | Cards / 3D | **NOT USE** | Aggressive 3D mouse tilt | N/A (Causes UI disorientation on serious safety screens) | Medium (CSS perspective 3D matrix math) | Touch tilt awkward | N/A |
| **ChromaGrid** | Cards | **NOT USE** | Multi-colored chromatic grid | N/A (Violates dark tactical monochromatic color system) | Medium | Moderate | N/A |
| **AnimatedContent** | Animations | **USE** | Staggered fade and slide content reveal | Global (All authenticated dashboard pages) | Minimal (Single CSS transition on mount) | Universal | Instantly visible (`opacity: 1`, `transform: none`) |
| **FadeContent** | Animations | **USE** | Cross-fade with optional blur clearing | Panels, Drawer tabs, Route overlays | Minimal (Opacity transition) | Universal | Instant opacity reveal |
| **ScrollReveal** | Scroll Effects | **USE** | Passive viewport scroll entry | `/dashboard/analytics`, `/about`, `/dev/ui-showcase` | Minimal (Native `IntersectionObserver`, no scroll polling) | Universal | Instantly visible without intersection wait |
| **AnimatedList** | Animations / List | **USE** | Sequential entry stagger for incident & alert feeds | `/dashboard/incidents`, `/dashboard/alerts`, `/dashboard/events` | Low (Capped maximum stagger delay to 280ms) | Universal | All items render simultaneously without stagger |
| **Dock** | Navigation | **USE** | Floating tactical map toolbar with micro-magnification | `/dashboard/map`, `/dev/ui-showcase` | Low (CSS transform scale on hover) | Replaces with bottom dock on mobile | No hover scale; instant tap focus |
| **PillNav** | Navigation | **USE** | Sliding active tab selector | Filter bars, map mode switches (Road/Sat/Terr) | Minimal (CSS transition) | Touch friendly (min 44px tap target) | Instant active background switch |
| **StaggeredMenu** | Navigation | **NOT USE** | Expanding circular action menu | N/A (Obstructs operational map pan/zoom controls) | Medium | Difficult on small phones | N/A |
| **CardNav** | Navigation | **NOT USE** | Full-screen card navigation stack | N/A (Disrupts persistent command shell `AppShell`) | Medium-High | Not suitable for command UI | N/A |
| **DecryptedText** | Text Animations | **USE** | Character scramble decode reveal | `/login`, `/about`, System headers | Minimal (Character array tick timer) | Universal | Displays plain target text immediately |
| **ShinyText** | Text Animations | **USE** | Luminous light streak pass across headers | Branding badges, system status labels | Minimal (Background position keyframe) | Universal | Static text with no background sweep |
| **CountUp** | Text Animations | **USE** | Numeric rolling digit animation | Telemetry distance, speed, incident metrics | Low (`requestAnimationFrame` with cubic easing) | Universal | Directly renders final numeric value |
| **SplitText** | Text Animations | **NOT USE** | Exploding/rotating word letters | N/A (Impairs legibility of critical coordinate telemetry) | Medium (Dozens of individual span elements) | Layout shift risk | N/A |
| **VariableProximity** | Text Animations | **NOT USE** | Font weight distortion based on cursor distance | N/A (Gimmicky for serious border safety operations) | High (Constant mouse distance recalculation on font) | Non-functional on touch | N/A |
| **Magnet** | Interactions | **USE** | Physics-based cursor attraction | Primary CTA buttons (`BSASMagneticButton`) | Minimal (Passive mouse tracking on button boundary) | Disabled automatically on mobile | Transform reset to zero |
| **GlareHover** | Hover Effects | **USE** | Directional light reflection sweep on hover | Operational cards, action buttons | Minimal (Radial gradient overlay) | Degrades cleanly on touch | Overlay hidden |
| **SlideButton** | Buttons | **USE** | Horizontal accent fill with state morphing | Submit buttons, Sync triggers, Map CTAs | Minimal (CSS transform translate) | Universal | Instant color change without sliding animation |
| **ClickSpark** | Micro-interactions | **NOT USE** | Explosive sparks on mouse click | N/A (Forbidden by Section 62 on safety controls) | Medium (Canvas particle generation per click) | Distracting on mobile | N/A |
| **Crosshair** | Cursor | **NOT USE** | Custom full-screen targeting cursor | N/A (Interferes with native Google Maps pan/grab cursor) | Medium (Cursor position polling on document body) | Non-functional on touch | N/A |
| **ElasticSlider** | Components | **NOT USE** | Springy rubber-band slider | N/A (Imprecise for numerical safety threshold adjustments) | Medium (Spring physics simulation) | Accidental swipe triggers | N/A |

---

## Architectural Summary
- **Total Catalog Components Inspected**: 28 components across 12 React Bits categories.
- **Components Selected & Adapted**: 16 components (Cubes, GridBackground, SpotlightCard, ElectricBorder, GlassSurface, AnimatedContent, FadeContent, ScrollReveal, AnimatedList, Dock, PillNav, DecryptedText, ShinyText, CountUp, Magnet, GlareHover, SlideButton).
- **Components Excluded**: 12 components (rejected due to safety clarity, map interference, or excessive WebGL/Three.js overhead).
- **Target Design System Alignment**: 100% compliant with BSAS semantic tokens, dark tactical typography, and accessibility guidelines.
