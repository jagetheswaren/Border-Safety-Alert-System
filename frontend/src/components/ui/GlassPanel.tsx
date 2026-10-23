"use client";

import React from "react";

interface GlassPanelProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  elevated?: boolean;
  className?: string;
}

export const GlassPanel: React.FC<GlassPanelProps> = ({
  children,
  elevated = false,
  className = "",
  ...props
}) => {
  return (
    <div
      className={`rounded-2xl ${
        elevated ? "glass-surface-elevated shadow-2xl" : "glass-surface shadow-xl"
      } ${className}`}
      {...props}
    >
      {children}
    </div>
  );
};
