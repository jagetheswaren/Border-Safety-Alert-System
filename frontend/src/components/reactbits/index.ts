/**
 * BSAS React Bits Local Component Library
 * Centralized, tactical adaptations of React Bits motion patterns.
 * 
 * Strict Performance Guidelines:
 * - Zero heavy WebGL backgrounds on the Live Map screen.
 * - All components strictly observe prefers-reduced-motion via isReducedMotion().
 * - Reusable across all BSAS tactical operational pages.
 */

// Animations
export { AnimatedContent } from "./animations/AnimatedContent";
export { FadeContent } from "./animations/FadeContent";
export { ScrollReveal } from "./animations/ScrollReveal";
export { AnimatedList } from "./animations/AnimatedList";

// Backgrounds
export { Cubes } from "./backgrounds/Cubes";
export { GridBackground } from "./backgrounds/GridBackground";

// Cards
export { SpotlightCard } from "./cards/SpotlightCard";
export { ElectricBorder } from "./cards/ElectricBorder";
export { GlassSurface } from "./cards/GlassSurface";

// Navigation
export { Dock, DockItem } from "./navigation/Dock";
export { PillNav } from "./navigation/PillNav";

// Text Animations
export { DecryptedText } from "./text/DecryptedText";
export { ShinyText } from "./text/ShinyText";
export { CountUp } from "./text/CountUp";

// Interactions
export { Magnet } from "./interactions/Magnet";
export { GlareHover } from "./interactions/GlareHover";
export { SlideButton } from "./interactions/SlideButton";
