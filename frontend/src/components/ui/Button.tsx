"use client";

import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger" | "mapControl";
  size?: "sm" | "md" | "lg";
  icon?: React.ReactNode;
  iconPosition?: "left" | "right";
  loading?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      children,
      variant = "primary",
      size = "md",
      icon,
      iconPosition = "left",
      loading = false,
      disabled,
      className = "",
      ...props
    },
    ref
  ) => {
    const baseStyles =
      "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none disabled:active:scale-100 select-none";

    const variantStyles = {
      primary:
        "bg-sky-600 hover:bg-sky-500 text-white shadow-md shadow-sky-600/30 hover:shadow-sky-500/40 border border-sky-400/20",
      secondary:
        "bg-slate-800/80 hover:bg-slate-700/80 text-slate-200 hover:text-white border border-slate-700/80 shadow-sm",
      ghost:
        "bg-transparent hover:bg-slate-800 text-slate-300 hover:text-white border border-transparent",
      danger:
        "bg-rose-600/90 hover:bg-rose-500 text-white shadow-md shadow-rose-600/30 border border-rose-500/20",
      mapControl:
        "bg-slate-900/90 hover:bg-slate-800 text-slate-200 hover:text-white border border-slate-700/70 shadow-lg backdrop-blur-md",
    }[variant];

    const sizeStyles = {
      sm: "px-2.5 py-1.5 text-xs gap-1.5",
      md: "px-4 py-2 text-xs gap-2",
      lg: "px-5 py-2.5 text-sm gap-2.5",
    }[size];

    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={`${baseStyles} ${variantStyles} ${sizeStyles} ${className}`}
        {...props}
      >
        {loading ? (
          <span className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin shrink-0" />
        ) : (
          icon && iconPosition === "left" && <span className="shrink-0">{icon}</span>
        )}
        <span>{children}</span>
        {!loading && icon && iconPosition === "right" && (
          <span className="shrink-0 transition-transform duration-150 group-hover:translate-x-0.5">
            {icon}
          </span>
        )}
      </button>
    );
  }
);

Button.displayName = "Button";
