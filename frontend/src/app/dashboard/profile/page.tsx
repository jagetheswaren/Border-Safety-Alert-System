"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { User, Shield, Mail, Key, LogOut } from "lucide-react";
import { getMe } from "@/lib/api";
import { User as UserType } from "@/lib/types";
import { AnimatedContent } from "@/components/reactbits/animations/AnimatedContent";
import { SpotlightCard } from "@/components/reactbits/cards/SpotlightCard";
import { BSASDangerButton } from "@/components/ui/BSASButtons";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function ProfilePage() {
  const router = useRouter();
  const [user, setUser] = useState<UserType | null>(null);

  useEffect(() => {
    let mounted = true;
    void (async () => {
      await Promise.resolve();
      try {
        const u = await getMe();
        if (mounted) setUser(u);
      } catch {
        // fallback
      }
    })();
    return () => {
      mounted = false;
    };
  }, []);

  const handleLogout = () => {
    localStorage.removeItem("token");
    router.replace("/login");
  };

  const displayName = user?.email ? user.email.split("@")[0].toUpperCase() : "BSAS FIELD OFFICER";
  const initials = displayName.slice(0, 2);

  return (
    <div className="max-w-4xl space-y-6">
      <AnimatedContent distance={12} duration={260}>
        <div>
          <div className="flex items-center gap-2 text-xs font-mono text-sky-400 uppercase tracking-widest mb-1">
            <span>OPERATOR</span>
            <span>/</span>
            <span>USER PROFILE</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
            <User className="w-6 h-6 text-sky-400" />
            Operator Credentials & Role
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Authenticated operational identity and RBAC authorization tier.
          </p>
        </div>
      </AnimatedContent>

      <AnimatedContent distance={16} delay={50}>
        <SpotlightCard className="p-8">
          <div className="flex flex-col sm:flex-row sm:items-center gap-6 pb-6 border-b border-slate-800">
            <div className="w-20 h-20 rounded-2xl bg-sky-600/20 border-2 border-sky-500/40 flex items-center justify-center text-2xl font-bold font-mono text-sky-400 shadow-xl shadow-sky-950/50 shrink-0">
              {initials}
            </div>

            <div className="space-y-1">
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-bold text-white">{displayName}</h2>
                <StatusBadge status="ONLINE" />
              </div>
              <p className="text-xs font-mono text-slate-400">{user?.email || "operator@bsas.internal"}</p>
              <div className="pt-2 flex items-center gap-2">
                <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-sky-500/10 border border-sky-500/20 text-sky-400 font-semibold uppercase">
                  ROLE: {user?.role || "OPERATOR"}
                </span>
                <span className="text-[11px] text-slate-500">ID: {user?.id || "USR-2026-ALPHA"}</span>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6">
            <div className="space-y-4">
              <h3 className="text-xs font-mono uppercase tracking-wider text-slate-400">
                Authorization & Permissions
              </h3>
              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-900/60 border border-slate-800">
                  <span className="text-slate-300 flex items-center gap-2">
                    <Shield className="w-3.5 h-3.5 text-sky-400" />
                    Geofence Demarcation Access
                  </span>
                  <span className="text-emerald-400 font-mono font-semibold">AUTHORIZED</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-900/60 border border-slate-800">
                  <span className="text-slate-300 flex items-center gap-2">
                    <Key className="w-3.5 h-3.5 text-sky-400" />
                    Emergency Dispatch Authorization
                  </span>
                  <span className="text-emerald-400 font-mono font-semibold">AUTHORIZED</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-900/60 border border-slate-800">
                  <span className="text-slate-300 flex items-center gap-2">
                    <Mail className="w-3.5 h-3.5 text-sky-400" />
                    Live Incident Resolution
                  </span>
                  <span className="text-emerald-400 font-mono font-semibold">
                    {user?.role === "FIELD_USER" ? "READ ONLY" : "AUTHORIZED"}
                  </span>
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-xs font-mono uppercase tracking-wider text-slate-400">
                Session Management
              </h3>
              <div className="p-4 rounded-xl bg-slate-900/60 border border-slate-800 text-xs space-y-3">
                <p className="text-slate-400">
                  You are logged into an active encrypted cryptographic session signed with HMAC-SHA256 JWT.
                </p>
                <div className="pt-2">
                  <BSASDangerButton
                    icon={<LogOut className="w-3.5 h-3.5" />}
                    onClick={handleLogout}
                  >
                    Terminate Current Session
                  </BSASDangerButton>
                </div>
              </div>
            </div>
          </div>
        </SpotlightCard>
      </AnimatedContent>
    </div>
  );
}
