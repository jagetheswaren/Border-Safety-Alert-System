"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getMe } from "@/lib/api";
import { User } from "@/lib/types";
import { Shield, LayoutDashboard, Map, FileText, AlertTriangle, Settings, LogOut } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    getMe()
      .then(setUser)
      .catch(() => router.push("/login"))
      .finally(() => setLoading(false));
  }, [router]);

  if (loading) {
    return <div className="min-h-screen bg-gray-950 flex items-center justify-center text-white">Loading BSAS...</div>;
  }

  const isActive = (path: string) => {
    if (path === "/dashboard") return pathname === "/dashboard";
    return pathname.startsWith(path);
  };

  return (
    <div className="min-h-screen bg-gray-950 text-white flex">
      {/* Sidebar */}
      <aside className="w-64 bg-gray-900 border-r border-gray-800 flex flex-col">
        <div className="h-16 flex items-center px-6 border-b border-gray-800">
          <Shield className="w-6 h-6 text-blue-500 mr-2" />
          <span className="font-bold text-lg tracking-wide">BSAS Ops</span>
        </div>
        
        <nav className="flex-1 py-6 px-4 space-y-1">
          <Link
            href="/dashboard"
            className={`flex items-center px-3 py-2.5 rounded-lg transition-colors ${
              isActive("/dashboard") ? "bg-gray-800 text-blue-400 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800/50"
            }`}
          >
            <LayoutDashboard className="w-5 h-5 mr-3" />
            Overview
          </Link>
          <Link
            href="/dashboard/map"
            className={`flex items-center px-3 py-2.5 rounded-lg transition-colors ${
              isActive("/dashboard/map") ? "bg-gray-800 text-blue-400 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800/50"
            }`}
          >
            <Map className="w-5 h-5 mr-3" />
            Live Map
          </Link>
          <Link
            href="/dashboard/incidents"
            className={`flex items-center px-3 py-2.5 rounded-lg transition-colors ${
              isActive("/dashboard/incidents") ? "bg-gray-800 text-blue-400 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800/50"
            }`}
          >
            <FileText className="w-5 h-5 mr-3" />
            Incidents
          </Link>
          <Link
            href="/dashboard/alerts"
            className={`flex items-center px-3 py-2.5 rounded-lg transition-colors ${
              isActive("/dashboard/alerts") ? "bg-gray-800 text-blue-400 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800/50"
            }`}
          >
            <AlertTriangle className="w-5 h-5 mr-3" />
            Alerts Feed
          </Link>
          {user?.role === "ADMIN" && (
            <Link
              href="/dashboard/settings"
              className={`flex items-center px-3 py-2.5 rounded-lg transition-colors ${
                isActive("/dashboard/settings") ? "bg-gray-800 text-blue-400 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800/50"
              }`}
            >
              <Settings className="w-5 h-5 mr-3" />
              Settings
            </Link>
          )}
        </nav>
        
        <div className="p-4 border-t border-gray-800">
          <div className="flex items-center mb-4 px-2">
            <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center font-bold text-sm">
              {user?.email[0].toUpperCase()}
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium">{user?.email}</p>
              <p className="text-xs text-gray-500">{user?.role}</p>
            </div>
          </div>
          <button 
            onClick={() => {
              localStorage.removeItem("token");
              router.push("/login");
            }}
            className="flex items-center w-full px-3 py-2 text-sm text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        {children}
      </main>
    </div>
  );
}
