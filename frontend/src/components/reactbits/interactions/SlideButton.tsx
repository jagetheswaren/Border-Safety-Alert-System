"use client";

import React from "react";
import { ArrowRight, Check, Loader2 } from "lucide-react";
import { isReducedMotion } from "@/lib/motion";

interface SlideButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  loadingLabel?: string;
  successLabel?: string;
  state?: "idle" | "loading" | "success" | "error";
  variant?: "primary" | "secondary" | "danger";
  showArrow?: boolean;
  className?: string;
}

/**
 * React Bits - SlideButton:
 * Tactile sliding button with horizontal accent fill on hover,
 * click compression, and state morphing (idle -> loading -> success).
 */
export const SlideButton: React.FC<SlideButtonProps> = ({
  label,
  loadingLabel = "PROCESSING...",
  successLabel = "CONFIRMED",
  state = "idle",
  variant = "primary",
  showArrow = true,
  className = "",
  disabled,
  onClick,
  ...props
}) => {
  const reduced = isReducedMotion();

  const variantStyles = {
    primary: "border-sky-500/50 bg-slate-900 text-sky-100 hover:border-sky-400",
    secondary: "border-slate-700 bg-slate-900/90 text-slate-200 hover:border-slate-600",
    danger: "border-rose-500/50 bg-slate-900 text-rose-100 hover:border-rose-400",
  }[variant];

  const fillStyles = {
    primary: "bg-gradient-to-r from-sky-600 to-blue-600",
    secondary: "bg-slate-800",
    danger: "bg-gradient-to-r from-rose-600 to-red-600",
  }[variant];

  return (
    <button
      type="button"
      onClick={state === "idle" ? onClick : undefined}
      disabled={disabled || state === "loading"}
      className={`group relative overflow-hidden rounded-xl border px-5 py-2.5 text-xs font-semibold tracking-wider transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 disabled:opacity-50 disabled:cursor-not-allowed ${
        !reduced ? "active:scale-[0.98]" : ""
      } ${variantStyles} ${className}`}
      {...props}
    >
      {/* Sliding Accent Background Layer */}
      <span
        className={`absolute inset-0 -translate-x-full transition-transform duration-300 ease-out group-hover:translate-x-0 ${fillStyles}`}
        aria-hidden="true"
      />

      {/* Button Content */}
      <span className="relative z-10 flex items-center justify-center gap-2">
        {state === "loading" ? (
          <>
            <Loader2 className="w-3.5 h-3.5 animate-spin text-sky-400" />
            <span>{loadingLabel}</span>
          </>
        ) : state === "success" ? (
          <>
            <Check className="w-3.5 h-3.5 text-emerald-400" />
            <span className="text-emerald-300">{successLabel}</span>
          </>
        ) : (
          <>
            <span
              className={`transition-transform duration-200 ${
                !reduced ? "group-hover:translate-x-0.5" : ""
              }`}
            >
              {label}
            </span>
            {showArrow && (
              <ArrowRight
                className={`w-3.5 h-3.5 transition-transform duration-200 ${
                  !reduced ? "group-hover:translate-x-1.5" : ""
                }`}
              />
            )}
          </>
        )}
      </span>
    </button>
  );
};
