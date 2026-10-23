"use client";

import React, { useEffect } from "react";
import { X } from "lucide-react";
import { IconButton } from "./IconButton";

interface DrawerProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  position?: "left" | "right";
  width?: string;
}

export const Drawer: React.FC<DrawerProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  position = "right",
  width = "max-w-md",
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen) onClose();
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-hidden" role="dialog" aria-modal="true">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-950/70 backdrop-blur-sm transition-opacity duration-300 animate-in fade-in"
        onClick={onClose}
        aria-hidden="true"
      />

      <div
        className={`fixed inset-y-0 ${
          position === "right" ? "right-0" : "left-0"
        } flex max-w-full`}
      >
        <div
          className={`w-screen ${width} bg-slate-900 border-l border-slate-800 shadow-2xl flex flex-col transition-transform duration-300 ease-out`}
        >
          {/* Header */}
          <div className="px-6 py-4 border-b border-slate-800 flex items-center justify-between bg-slate-900/90 backdrop-blur-md">
            <div>
              <h2 className="text-base font-semibold text-white tracking-tight">
                {title}
              </h2>
              {subtitle && (
                <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>
              )}
            </div>
            <IconButton
              icon={<X className="w-4 h-4" />}
              title="Close drawer (Esc)"
              variant="ghost"
              onClick={onClose}
            />
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto p-6">{children}</div>
        </div>
      </div>
    </div>
  );
};
