"use client";

import React from "react";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Bot,
  ShieldCheck,
  Shield,
  LayoutDashboard,
  Map,
  FileText,
  Bell,
  Users,
  Layers,
  Activity,
  BarChart3,
  User as UserIcon,
  RefreshCw,
  HeartPulse,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { User } from "@/lib/types";

interface SidebarProps {
  user: User | null;
  collapsed: boolean;
  onToggleCollapse: () => void;
  onCloseMobile?: () => void;
}

interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string | number;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

export const Sidebar: React.FC<SidebarProps> = ({
  user,
  collapsed,
  onToggleCollapse,
  onCloseMobile,
}) => {
  const pathname = usePathname();
  const router = useRouter();

  const sections: NavSection[] = [
    {
      title: "OPERATIONS",
      items: [
        { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
        { href: "/dashboard/map", label: "Live Map", icon: Map },
        { href: "/dashboard/incidents", label: "Incidents", icon: FileText },
        { href: "/dashboard/alerts", label: "Alerts", icon: Bell },
        { href: "/dashboard/devices", label: "Field Units", icon: Users },
      ],
    },
    {
      title: "INTELLIGENCE",
      items: [
        { href: "/dashboard/ai", label: "AI Assistant", icon: Bot },
        { href: "/dashboard/boundaries", label: "Boundaries", icon: Shield },
        { href: "/dashboard/zones", label: "Safety Zones", icon: Layers },
        { href: "/dashboard/analytics", label: "Analytics", icon: BarChart3 },
        { href: "/dashboard/events", label: "Activity Logs", icon: Activity },
      ],
    },
    {
      title: "SYSTEM",
      items: [
        { href: "/dashboard/sync", label: "Sync Center", icon: RefreshCw },
        { href: "/dashboard/health", label: "System Health", icon: HeartPulse },
        { href: "/dashboard/profile", label: "Profile", icon: UserIcon },
        { href: "/dashboard/settings", label: "Settings", icon: Settings },
      ],
    },
  ];

  const handleSignOut = () => {
    localStorage.removeItem("token");
    router.replace("/login");
  };

  const isActive = (href: string) => {
    if (href === "/dashboard") return pathname === "/dashboard";
    return pathname.startsWith(href);
  };

  return (
    <aside
      className={`fixed top-0 bottom-0 left-0 z-40 flex flex-col bg-slate-900 border-r border-slate-800 transition-all duration-300 ease-out select-none ${
        collapsed ? "w-[72px]" : "w-[250px]"
      }`}
    >
      {/* Brand Header */}
      <div className="h-14 px-4 border-b border-slate-800 flex items-center justify-between">
        <Link
          href="/dashboard"
          onClick={onCloseMobile}
          className="flex items-center gap-3 overflow-hidden"
        >
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-sky-500 to-blue-600 flex items-center justify-center text-white shadow-md shadow-sky-500/20 shrink-0">
            <ShieldCheck className="w-4 h-4" />
          </div>
          {!collapsed && (
            <div className="min-w-0 transition-opacity duration-200">
              <span className="text-sm font-bold tracking-wider text-white">
                BSAS
              </span>
              <span className="block text-[9px] font-semibold tracking-widest text-sky-400 uppercase -mt-0.5">
                Operations
              </span>
            </div>
          )}
        </Link>

        {/* Collapse toggle (desktop only) */}
        <button
          type="button"
          onClick={onToggleCollapse}
          className="hidden md:flex items-center justify-center w-6 h-6 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          title={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          {collapsed ? (
            <ChevronRight className="w-3.5 h-3.5" />
          ) : (
            <ChevronLeft className="w-3.5 h-3.5" />
          )}
        </button>
      </div>

      {/* Nav items list */}
      <div className="flex-1 overflow-y-auto px-3 py-3 space-y-5">
        {sections.map((sec) => (
          <div key={sec.title}>
            {!collapsed && (
              <p className="px-3 mb-1.5 text-[10px] font-bold tracking-wider uppercase text-slate-400">
                {sec.title}
              </p>
            )}
            <nav className="space-y-1">
              {sec.items.map(({ href, label, icon: Icon, badge }) => {
                const active = isActive(href);
                return (
                  <Link
                    key={href}
                    href={href}
                    onClick={onCloseMobile}
                    title={collapsed ? label : undefined}
                    className={`group relative flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium transition-all duration-200 ${
                      active
                        ? "bg-sky-600 text-white shadow-md shadow-sky-600/30 font-semibold"
                        : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/60"
                    } ${collapsed ? "justify-center px-0" : ""}`}
                  >
                    <Icon
                      className={`w-4 h-4 shrink-0 transition-transform duration-150 group-hover:scale-110 ${
                        active ? "text-white" : "text-slate-400 group-hover:text-sky-400"
                      }`}
                    />
                    {!collapsed && (
                      <span className="truncate flex-1">{label}</span>
                    )}
                    {!collapsed && badge && (
                      <span className="px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-800 text-sky-400 border border-slate-700">
                        {badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </nav>
          </div>
        ))}
      </div>

      {/* Profile & Signout footer */}
      <div className="p-3 border-t border-slate-800 bg-slate-900/60">
        <div
          className={`flex items-center gap-3 p-2 rounded-xl bg-slate-800/60 border border-slate-700/60 ${
            collapsed ? "justify-center p-1.5" : ""
          }`}
        >
          <div className="w-7 h-7 rounded-lg bg-sky-700 text-white font-bold text-xs flex items-center justify-center shrink-0">
            {user?.email ? user.email[0].toUpperCase() : "U"}
          </div>
          {!collapsed && (
            <div className="min-w-0 flex-1">
              <p className="text-xs font-semibold text-white truncate">
                {user?.email || "Operator"}
              </p>
              <p className="text-[10px] text-sky-400 uppercase font-medium">
                {user?.role || "OPERATOR"}
              </p>
            </div>
          )}
          {!collapsed && (
            <button
              type="button"
              onClick={handleSignOut}
              title="Sign out"
              className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-950/40 rounded-lg transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
};
