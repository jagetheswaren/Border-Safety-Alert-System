"use client";

import React from "react";
import { ArrowRight, Check, AlertCircle } from "lucide-react";

export interface SlideActionButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  loadingLabel?: string;
  successLabel?: string;
  status?: "idle" | "loading" | "success" | "error";
  icon?: React.ReactNode;
}

/**
 * SlideActionButton:
 * Premium sliding button animation as specified in BSAS UI/UX Rebuild master spec.
 */
export const SlideActionButton: React.FC<SlideActionButtonProps> = ({
  label,
  loadingLabel = "Authenticating...",
  successLabel = "Access Granted",
  status = "idle",
  icon = <ArrowRight className="w-4 h-4 ml-1 transition-transform duration-200 group-hover:translate-x-1" />,
  disabled,
  className = "",
  ...props
}) => {
  const isLoading = status === "loading";
  const isSuccess = status === "success";
  const isError = status === "error";

  return (
    <button
      disabled={disabled || isLoading || isSuccess}
      className={`group relative overflow-hidden rounded-xl border px-5 py-3 text-xs font-semibold select-none transition-all duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400 active:scale-[0.98] ${
        isSuccess
          ? "border-emerald-500 bg-emerald-600 text-white shadow-lg shadow-emerald-500/30"
          : isError
          ? "border-rose-500 bg-rose-600/90 text-white shadow-lg shadow-rose-500/30"
          : "border-sky-500/40 bg-slate-900 text-sky-100 shadow-md shadow-sky-600/20 hover:border-sky-400"
      } ${className}`}
      {...props}
    >
      {/* Sliding background layer */}
      {!isSuccess && !isError && (
        <span
          className="absolute inset-0 bg-gradient-to-r from-sky-600 to-cyan-500 transition-transform duration-300 ease-out -translate-x-full group-hover:translate-x-0"
          aria-hidden="true"
        />
      )}

      {/* Content wrapper */}
      <span className="relative z-10 flex items-center justify-center gap-2">
        {isLoading && (
          <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
        )}

        {isSuccess && <Check className="w-4 h-4 text-white animate-bounce" />}
        {isError && <AlertCircle className="w-4 h-4 text-white" />}

        <span className="tracking-wide">
          {isLoading
            ? loadingLabel
            : isSuccess
            ? successLabel
            : label}
        </span>

        {!isLoading && !isSuccess && !isError && icon}
      </span>
    </button>
  );
};
