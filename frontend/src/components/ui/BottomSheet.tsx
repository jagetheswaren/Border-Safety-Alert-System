"use client";

import React, { useEffect } from "react";
import { X } from "lucide-react";
import { IconButton } from "./IconButton";

interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  maxHeight?: string;
}

export const BottomSheet: React.FC<BottomSheetProps> = ({
  isOpen,
  onClose,
  title,
  children,
  maxHeight = "max-h-[82vh]",
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
    <div className="fixed inset-0 z-50 md:hidden flex flex-col justify-end" role="dialog" aria-modal="true">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-slate-950/70 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Sheet Container */}
      <div
        className={`relative z-10 w-full bg-slate-900 border-t border-slate-800 rounded-t-3xl shadow-2xl flex flex-col ${maxHeight} overflow-hidden`}
      >
        {/* Drag handle */}
        <div className="w-full flex justify-center pt-3 pb-1" onClick={onClose}>
          <div className="w-10 h-1 bg-slate-700 rounded-full" />
        </div>

        {/* Header */}
        <div className="px-5 py-3 border-b border-slate-800 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white">{title}</h3>
          <IconButton
            icon={<X className="w-4 h-4" />}
            title="Close sheet"
            variant="ghost"
            size="sm"
            onClick={onClose}
          />
        </div>

        {/* Scrollable content */}
        <div className="flex-1 overflow-y-auto p-5">{children}</div>
      </div>
    </div>
  );
};
