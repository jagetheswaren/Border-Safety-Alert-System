"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";
import { MobileNavigation } from "./MobileNavigation";
import { CommandPalette } from "./CommandPalette";
import { ToastProvider } from "@/components/ui/Toast";
import { LoadingState } from "@/components/ui/LoadingState";
import { useResource } from "@/lib/use-resource";
import { getMe, isOperator, SESSION_EXPIRED } from "@/lib/api";

interface AppShellProps {
  children: React.ReactNode;
}

export const AppShell: React.FC<AppShellProps> = ({ children }) => {
  const router = useRouter();
  const { data: user, error, loading, refresh } = useResource(getMe);
  const [collapsed, setCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false);

  useEffect(() => {
    window.addEventListener('online', refresh);
    return () => window.removeEventListener('online', refresh);
  }, [refresh]);

  // Global hotkey Ctrl+K / Cmd+K
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        setCommandPaletteOpen((prev) => !prev);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Listen to session expiry
  useEffect(() => {
    const expired = () => router.replace("/login?reason=expired");
    window.addEventListener(SESSION_EXPIRED, expired);
    if (!localStorage.getItem("token")) router.replace("/login");
    return () => window.removeEventListener(SESSION_EXPIRED, expired);
  }, [router]);

  useEffect(() => {
    if (user && !isOperator(user)) {
      localStorage.removeItem("token");
      router.replace("/login?reason=role");
    }
  }, [user, router]);

  if (loading) {
    return <LoadingState variant="fullscreen" label="Verifying BSAS Operator Credentials..." />;
  }

  if (error || !user || !isOperator(user)) {
    return <div className="m-auto max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 text-slate-200">
      <h1 className="text-lg font-semibold">BSAS connection unavailable</h1>
      <p role="alert" className="my-3">{error?.message || 'Please sign in with an active operator account.'}</p>
      <p className="mb-4 text-sm text-slate-400">No current safety status can be confirmed until the connection is restored.</p>
      <button onClick={refresh} className="mr-4 rounded bg-sky-800 px-4 py-2">Retry connection</button>
      <button onClick={() => router.replace('/login')} className="underline">Sign in</button>
    </div>;
  }

  return (
    <ToastProvider>
      <div className="min-h-screen bg-slate-950 text-slate-100 flex">
        {/* Desktop Collapsible Sidebar */}
        <div className="hidden md:block">
          <Sidebar
            user={user}
            collapsed={collapsed}
            onToggleCollapse={() => setCollapsed(!collapsed)}
          />
        </div>

        {/* Mobile Drawer Sidebar */}
        {mobileMenuOpen && (
          <div className="fixed inset-0 z-50 md:hidden flex" role="dialog" aria-modal="true">
            <div
              className="fixed inset-0 bg-slate-950/80 backdrop-blur-sm"
              onClick={() => setMobileMenuOpen(false)}
            />
            <div className="relative z-10 w-72 h-full bg-slate-900 border-r border-slate-800">
              <Sidebar
                user={user}
                collapsed={false}
                onToggleCollapse={() => {}}
                onCloseMobile={() => setMobileMenuOpen(false)}
              />
            </div>
          </div>
        )}

        {/* Main Content Area */}
        <div
          className={`flex-1 flex flex-col min-w-0 transition-all duration-300 ${
            collapsed ? "md:ml-[72px]" : "md:ml-[250px]"
          } pb-16 md:pb-0`}
        >
          <TopBar
            user={user}
            onOpenMobileMenu={() => setMobileMenuOpen(true)}
            onOpenCommandPalette={() => setCommandPaletteOpen(true)}
          />

          <main id="main-content" className="flex-1 flex flex-col min-w-0 overflow-y-auto">
            {children}
          </main>

          <MobileNavigation onOpenMore={() => setMobileMenuOpen(true)} />
        </div>

        {/* Global Command Palette */}
        <CommandPalette
          isOpen={commandPaletteOpen}
          onClose={() => setCommandPaletteOpen(false)}
        />
      </div>
    </ToastProvider>
  );
};
