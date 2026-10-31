"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Map,
  Bot,
  Bell,
  MoreHorizontal,
} from "lucide-react";

interface MobileNavigationProps {
  onOpenMore: () => void;
}

export const MobileNavigation: React.FC<MobileNavigationProps> = ({
  onOpenMore,
}) => {
  const pathname = usePathname();

  const links = [
    { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
    { href: "/dashboard/map", label: "Map", icon: Map },
    { href: "/dashboard/ai", label: "AI", icon: Bot },
    { href: "/dashboard/alerts", label: "Alerts", icon: Bell },
  ];

  const isActive = (href: string) => {
    if (href === "/dashboard") return pathname === "/dashboard";
    return pathname.startsWith(href);
  };

  return (
    <nav
      className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-slate-900/95 backdrop-blur-lg border-t border-slate-800 px-2 py-1 flex items-center justify-around select-none"
      aria-label="Mobile Navigation"
    >
      {links.map(({ href, label, icon: Icon }) => {
        const active = isActive(href);
        return (
          <Link
            key={href}
            href={href}
            className={`flex flex-col items-center justify-center py-1.5 px-3 rounded-xl text-[10px] font-medium transition-colors ${
              active
                ? "text-sky-400 font-bold"
                : "text-slate-400 hover:text-slate-200"
            }`}
          >
            <Icon className={`w-5 h-5 mb-0.5 ${active ? "text-sky-400" : ""}`} />
            <span>{label}</span>
          </Link>
        );
      })}

      <button
        type="button"
        onClick={onOpenMore}
        className="flex flex-col items-center justify-center py-1.5 px-3 rounded-xl text-[10px] font-medium text-slate-400 hover:text-slate-200"
      >
        <MoreHorizontal className="w-5 h-5 mb-0.5" />
        <span>More</span>
      </button>
    </nav>
  );
};
