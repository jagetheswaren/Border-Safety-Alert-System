"use client";

import React from "react";

export interface IconButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  icon: React.ReactNode;
  title: string;
  variant?: "default" | "active" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
}

export const IconButton = React.forwardRef<HTMLButtonElement, IconButtonProps>(
  (
    {
      icon,
      title,
      variant = "default",
      size = "md",
      className = "",
      ...props
    },
    ref
  ) => {
    const variantStyles = {
      default:
        "bg-slate-800/80 text-slate-300 hover:bg-slate-700 hover:text-white border border-slate-700/80",
      active:
        "bg-sky-600 text-white shadow-md shadow-sky-600/30 border border-sky-400/40",
      ghost:
        "bg-transparent text-slate-400 hover:text-white hover:bg-slate-800/50 border border-transparent",
      danger:
        "bg-rose-950/60 text-rose-300 hover:bg-rose-900 border border-rose-800/60",
    }[variant];

    const sizeStyles = {
      sm: "w-8 h-8 p-1.5 rounded-lg",
      md: "w-9 h-9 p-2 rounded-xl",
      lg: "w-11 h-11 p-2.5 rounded-xl",
    }[size];

    return (
      <button
        ref={ref}
        type="button"
        title={title}
        aria-label={title}
        className={`group relative inline-flex items-center justify-center transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 active:scale-95 disabled:opacity-50 disabled:pointer-events-none ${variantStyles} ${sizeStyles} ${className}`}
        {...props}
      >
        <span className="transition-transform duration-150 group-hover:scale-105">
          {icon}
        </span>
      </button>
    );
  }
);

IconButton.displayName = "IconButton";
