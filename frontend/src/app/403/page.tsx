"use client";

import React from "react";
import Link from "next/link";
import { ShieldAlert, ArrowLeft } from "lucide-react";
import { AnimatedContent } from "@/components/reactbits/animations/AnimatedContent";
import { GridBackground } from "@/components/reactbits/backgrounds/GridBackground";
import { BSASPrimaryButton } from "@/components/ui/BSASButtons";

export default function ForbiddenPage() {
  return (
    <div className="relative min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-6 overflow-hidden">
      <GridBackground className="opacity-20" />

      <AnimatedContent distance={16} duration={280} className="relative z-10 max-w-md w-full text-center">
        <div className="p-8 rounded-2xl bg-slate-900/80 border border-slate-800 shadow-2xl backdrop-blur-md space-y-6">
          <div className="w-16 h-16 mx-auto rounded-2xl bg-rose-500/10 border border-rose-500/30 flex items-center justify-center text-rose-400">
            <ShieldAlert className="w-8 h-8" />
          </div>

          <div>
            <span className="text-[11px] font-mono text-rose-400 uppercase tracking-widest block mb-1">
              SECURITY // HTTP 403
            </span>
            <h1 className="text-2xl font-bold text-white tracking-tight">Access Restricted</h1>
            <p className="text-xs text-slate-400 mt-2 leading-relaxed">
              Your assigned operational role does not possess the requisite RBAC authorization tier to inspect or modify this module.
            </p>
          </div>

          <div className="pt-2 flex justify-center">
            <Link href="/dashboard">
              <BSASPrimaryButton size="md" icon={<ArrowLeft className="w-4 h-4" />}>
                Return to Operations Dashboard
              </BSASPrimaryButton>
            </Link>
          </div>
        </div>
      </AnimatedContent>
    </div>
  );
}
