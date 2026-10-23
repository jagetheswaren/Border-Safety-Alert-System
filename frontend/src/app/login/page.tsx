"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ShieldCheck, LockKeyhole, Mail, Key } from "lucide-react";
import { login, getMe, isOperator } from "@/lib/api";
import { Cubes } from "@/components/reactbits/Cubes";
import { DecryptedText } from "@/components/reactbits/DecryptedText";
import { SlideActionButton } from "@/components/ui/SlideActionButton";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const router = useRouter();

  useEffect(() => {
    const reason = new URLSearchParams(window.location.search).get("reason");
    queueMicrotask(() => {
      if (reason === "expired") {
        setError("Your session has expired. Please authenticate again.");
      }
      if (reason === "role") {
        setError(
          "Dashboard access requires an active ADMIN or OPERATOR account. Field units use the BSAS mobile app."
        );
      }
    });
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus("loading");
    setError("");

    try {
      const response = await login(email.trim(), password);
      localStorage.setItem("token", response.access_token);
      const user = await getMe();

      if (!isOperator(user)) {
        throw new Error(
          "Access denied. Operational dashboard requires an ADMIN or OPERATOR account."
        );
      }

      setStatus("success");
      setTimeout(() => {
        router.replace("/dashboard");
      }, 700);
    } catch (err: unknown) {
      localStorage.removeItem("token");
      setStatus("error");
      setError(
        err instanceof Error
          ? err.message
          : "Unable to authenticate. Verify operator credentials."
      );
      setTimeout(() => setStatus("idle"), 2500);
    }
  };

  return (
    <div className="relative min-h-screen bg-slate-950 flex overflow-hidden">
      {/* Visual Left Section (60% Desktop) */}
      <div className="hidden lg:flex lg:w-7/12 relative flex-col justify-between p-12 overflow-hidden border-r border-slate-800/80 bg-slate-950">
        {/* React Bits Cubes Background */}
        <Cubes className="opacity-70" gridSize={8} cubeSize={40} />

        {/* Tactical Coordinate Grid Overlay */}
        <div className="absolute inset-0 bg-tactical-grid opacity-30 pointer-events-none" />

        {/* Ambient Gradient Glow */}
        <div className="absolute -top-32 -left-32 w-96 h-96 rounded-full bg-sky-500/10 blur-3xl pointer-events-none" />
        <div className="absolute -bottom-32 -right-32 w-96 h-96 rounded-full bg-blue-600/10 blur-3xl pointer-events-none" />

        {/* Header Branding */}
        <div className="relative z-10 flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-sky-500 to-blue-600 flex items-center justify-center text-white shadow-xl shadow-sky-500/30">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <span className="text-lg font-bold tracking-wider text-white">BSAS</span>
            <span className="block text-[10px] font-semibold tracking-widest text-sky-400 uppercase">
              Border Safety & Alert System
            </span>
          </div>
        </div>

        {/* Center Presentation Copy */}
        <div className="relative z-10 max-w-lg my-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-950/80 border border-sky-800/60 text-[11px] font-semibold text-sky-300 tracking-wide uppercase">
            <span className="w-1.5 h-1.5 rounded-full bg-sky-400 animate-pulse" />
            Tactical Operations Command Platform
          </div>

          <h1 className="text-3xl xl:text-4xl font-extrabold text-white tracking-tight leading-tight">
            Real-time geospatial awareness & monitored perimeter safety.
          </h1>

          <p className="text-xs xl:text-sm text-slate-400 leading-relaxed">
            Coordinating authoritative boundary datasets, high-precision telemetry,
            on-device neural risk models, and instant proximity warnings.
          </p>
        </div>

        {/* Footer Provenance */}
        <div className="relative z-10 pt-6 border-t border-slate-800/80 flex items-center justify-between text-[11px] text-slate-400">
          <span>BSAS Core Platform · Enterprise Edition</span>
          <span>FastAPI · Next.js · Google Maps Platform</span>
        </div>
      </div>

      {/* Authentication Panel (40% Desktop / Full Mobile) */}
      <div className="w-full lg:w-5/12 flex items-center justify-center p-6 sm:p-12 relative z-10">
        <div className="w-full max-w-md space-y-7">
          {/* Mobile Header */}
          <div className="lg:hidden flex items-center gap-3 mb-4">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-sky-500 to-blue-600 flex items-center justify-center text-white shadow-lg">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <span className="text-base font-bold text-white tracking-wider">BSAS</span>
              <span className="block text-[9px] font-semibold text-sky-400 uppercase">
                Border Safety & Alert System
              </span>
            </div>
          </div>

          <div>
            <div className="inline-flex items-center gap-2 text-xs font-semibold tracking-wider text-sky-400 uppercase">
              <DecryptedText text="SECURE OPERATOR ACCESS" speed={30} />
            </div>
            <h2 className="text-2xl font-bold text-white tracking-tight mt-1">
              Sign In to Command Center
            </h2>
            <p className="text-xs text-slate-400 mt-1">
              Enter authorized administrator or operator credentials.
            </p>
          </div>

          {error && (
            <div
              role="alert"
              className="p-3.5 rounded-xl border border-rose-800/80 bg-rose-950/70 text-rose-300 text-xs flex items-start gap-2.5 animate-in fade-in"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-rose-400 mt-1.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="email"
                className="block text-xs font-semibold text-slate-300 mb-1.5"
              >
                Operator Email
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  id="email"
                  type="email"
                  required
                  autoComplete="username"
                  placeholder="operator@bsas.gov"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={status === "loading" || status === "success"}
                  className="w-full rounded-xl bg-slate-900 border border-slate-700/80 pl-10 pr-3.5 py-2.5 text-xs text-white placeholder-slate-400 focus:outline-none focus:border-sky-400 focus:ring-1 focus:ring-sky-400 transition-colors"
                />
              </div>
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-xs font-semibold text-slate-300 mb-1.5"
              >
                Access Key / Password
              </label>
              <div className="relative">
                <Key className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  id="password"
                  type="password"
                  required
                  autoComplete="current-password"
                  placeholder="••••••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={status === "loading" || status === "success"}
                  className="w-full rounded-xl bg-slate-900 border border-slate-700/80 pl-10 pr-3.5 py-2.5 text-xs text-white placeholder-slate-400 focus:outline-none focus:border-sky-400 focus:ring-1 focus:ring-sky-400 transition-colors"
                />
              </div>
            </div>

            <div className="pt-2">
              <SlideActionButton
                label="SIGN IN TO WORKSPACE"
                loadingLabel="AUTHENTICATING OPERATOR..."
                successLabel="ACCESS GRANTED ✓"
                status={status}
                type="submit"
                className="w-full py-3"
              />
            </div>
          </form>

          {/* Footnote */}
          <div className="pt-4 border-t border-slate-800 text-[11px] text-slate-400 flex items-center gap-2">
            <LockKeyhole className="w-3.5 h-3.5 text-slate-400 shrink-0" />
            <span>Authorized access only. Session events and telemetry are logged.</span>
          </div>
        </div>
      </div>
    </div>
  );
}
