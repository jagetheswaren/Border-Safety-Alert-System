"use client";

import React from "react";
import { Button, ButtonProps } from "./Button";
import { IconButton } from "./IconButton";
import { SlideButton } from "@/components/reactbits/interactions/SlideButton";
import { Magnet } from "@/components/reactbits/interactions/Magnet";

export type BSASButtonBaseProps = Omit<ButtonProps, "variant">;

/**
 * BSAS Unified Button System
 * Built on React Bits interaction concepts with tactical feedback and WCAG compliance.
 */

// 1. Primary Action Button (Tactical Sky Accent)
export const BSASPrimaryButton: React.FC<BSASButtonBaseProps> = (props) => (
  <Button variant="primary" {...props} />
);

// 2. Secondary Button (Elevated Slate Surface)
export const BSASSecondaryButton: React.FC<BSASButtonBaseProps> = (props) => (
  <Button variant="secondary" {...props} />
);

// 3. Ghost Button (Subtle Minimal Borderless)
export const BSASGhostButton: React.FC<BSASButtonBaseProps> = (props) => (
  <Button variant="ghost" {...props} />
);

// 4. Danger Button (Controlled High-Priority Red)
export const BSASDangerButton: React.FC<BSASButtonBaseProps> = (props) => (
  <Button variant="danger" {...props} />
);

// 5. Icon Button (Tactile 40x40px Target)
export { IconButton as BSASIconButton };

// 6. Slide Action Button (Horizontal Fill Transition with State Morphing)
export { SlideButton as BSASSlideButton };

// 7. Magnetic Button (React Bits Magnet Wrapper for Critical CTAs)
interface BSASMagneticButtonProps extends BSASButtonBaseProps {
  strength?: number;
}

export const BSASMagneticButton: React.FC<BSASMagneticButtonProps> = ({
  strength = 10,
  children,
  ...props
}) => (
  <Magnet strength={strength}>
    <Button variant="primary" {...props}>
      {children}
    </Button>
  </Magnet>
);
