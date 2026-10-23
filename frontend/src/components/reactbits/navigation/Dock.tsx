"use client";

import React from "react";

interface DockItemProps {
  children: React.ReactNode;
  onClick?: () => void;
  title?: string;
  active?: boolean;
  className?: string;
}

export const DockItem: React.FC<DockItemProps> = ({
  children,
  onClick,
  title,
  active = false,
  className = "",
}) => {
  return (
    <button
      type="button"
      onClick={onClick}
      title={title}
      className={`group relative flex items-center justify-center w-10 h-10 rounded-xl transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 ${
        active
          ? "bg-sky-600 text-white shadow-lg shadow-sky-600/40"
          : "bg-slate-900/80 text-slate-300 hover:bg-slate-800 hover:text-white"
      } ${className}`}
    >
      <div className="transition-transform duration-150 group-hover:scale-110">
        {children}
      </div>
      {title && (
        <span className="pointer-events-none absolute right-full mr-2 hidden rounded-md bg-slate-950/90 px-2 py-1 text-[11px] font-medium text-slate-200 shadow-md backdrop-blur-md whitespace-nowrap group-hover:block z-50">
          {title}
        </span>
      )}
    </button>
  );
};

interface DockProps {
  children: React.ReactNode;
  className?: string;
  direction?: "vertical" | "horizontal";
}

/**
 * React Bits - Dock:
 * Floating tactical toolbar with subtle magnification and frosted glass blur.
 */
export const Dock: React.FC<DockProps> = ({
  children,
  className = "",
  direction = "vertical",
}) => {
  return (
    <nav
      className={`glass-surface flex gap-1.5 p-1.5 rounded-2xl shadow-2xl ${
        direction === "vertical" ? "flex-col" : "flex-row items-center"
      } ${className}`}
      aria-label="Map Control Dock"
    >
      {children}
    </nav>
  );
};
