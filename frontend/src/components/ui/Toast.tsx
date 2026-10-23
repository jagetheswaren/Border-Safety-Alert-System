"use client";

import React, { createContext, useContext, useState, useCallback } from "react";
import { CheckCircle2, AlertTriangle, AlertCircle, Info, X } from "lucide-react";

type ToastType = "success" | "warning" | "error" | "info";

interface ToastMessage {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
}

interface ToastContextType {
  showToast: (type: ToastType, title: string, message?: string) => void;
}

const ToastContext = createContext<ToastContextType | null>(null);

export const useToast = () => {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
};

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [toasts, setToasts] = useState<ToastMessage[]>([]);

  const showToast = useCallback(
    (type: ToastType, title: string, message?: string) => {
      const id = `${Date.now()}-${Math.random()}`;
      setToasts((prev) => [...prev.slice(-4), { id, type, title, message }]);
      setTimeout(() => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
      }, 4500);
    },
    []
  );

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  return (
    <ToastContext.Provider value={{ showToast }}>
      {children}
      <div className="fixed bottom-5 right-5 z-50 flex flex-col gap-2 pointer-events-none max-w-sm w-full">
        {toasts.map((t) => {
          const icon = {
            success: <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />,
            warning: <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />,
            error: <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />,
            info: <Info className="w-4 h-4 text-sky-400 shrink-0" />,
          }[t.type];

          const border = {
            success: "border-emerald-800/80 bg-slate-900/95 text-emerald-100",
            warning: "border-amber-800/80 bg-slate-900/95 text-amber-100",
            error: "border-rose-800/80 bg-slate-900/95 text-rose-100",
            info: "border-sky-800/80 bg-slate-900/95 text-sky-100",
          }[t.type];

          return (
            <div
              key={t.id}
              role="alert"
              className={`pointer-events-auto flex items-start gap-3 p-3.5 rounded-xl border shadow-2xl backdrop-blur-md transition-all duration-300 ${border}`}
            >
              {icon}
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-white">{t.title}</p>
                {t.message && (
                  <p className="text-[11px] text-slate-300 mt-0.5">{t.message}</p>
                )}
              </div>
              <button
                type="button"
                onClick={() => removeToast(t.id)}
                className="text-slate-400 hover:text-white p-1 rounded-md"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
};
