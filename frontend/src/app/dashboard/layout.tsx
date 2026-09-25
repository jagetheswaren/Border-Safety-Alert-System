"use client";
import { useEffect, useState } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { Activity, ShieldCheck, LayoutDashboard, Map, FileText, Bell, Layers, LogOut, Menu, ChevronRight } from 'lucide-react';
import { getMe, isOperator, SESSION_EXPIRED } from '@/lib/api';
import { useResource } from '@/lib/use-resource';
import { ErrorState, LoadingState } from '@/components/Workspace';

const navigation = [
  { href: '/dashboard', label: 'Overview', icon: LayoutDashboard },
  { href: '/dashboard/map', label: 'Safety map', icon: Map },
  { href: '/dashboard/incidents', label: 'Incidents', icon: FileText },
  { href: '/dashboard/alerts', label: 'Alerts', icon: Bell },
  { href: '/dashboard/zones', label: 'Safety zones', icon: Layers },
  { href: '/dashboard/status', label: 'System status', icon: Activity },
];
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { data: user, error, loading, refresh } = useResource(getMe);
  const [menuOpen, setMenuOpen] = useState(false);
  const router = useRouter();
  const pathname = usePathname();
  useEffect(() => {
    const expired = () => router.replace('/login?reason=expired');
    window.addEventListener(SESSION_EXPIRED, expired);
    if (!localStorage.getItem('token')) router.replace('/login');
    return () => window.removeEventListener(SESSION_EXPIRED, expired);
  }, [router]);
  useEffect(() => {
    if (user && !isOperator(user)) {
      localStorage.removeItem('token');
      router.replace('/login?reason=role');
    }
  }, [user, router]);
  if (loading) return <LoadingState label="Checking your workspace access…" />;
  if (error) return <ErrorState error={error} retry={refresh} />;
  if (!user || !isOperator(user)) return <LoadingState label="Returning to sign in…" />;
  const active = (href: string) => href === '/dashboard' ? pathname === href : pathname.startsWith(href);
  const current = navigation.find(item => active(item.href));
  return <div className="workspace">
    <button aria-label="Close navigation" className={`backdrop ${menuOpen ? 'visible' : ''}`} onClick={() => setMenuOpen(false)} />
    <aside className={`sidebar ${menuOpen ? 'open' : ''}`} id="workspace-navigation">
      <Link href="/dashboard" className="brand" onClick={() => setMenuOpen(false)}><span className="brand-icon"><ShieldCheck size={25} /></span><span><strong>BSAS</strong><small>BORDER SAFETY ALERT SYSTEM</small></span></Link>
      <p className="sidebar-label">WORKSPACE</p>
      <nav aria-label="Main navigation">{navigation.map(({ href, label, icon: Icon }) => <Link key={href} href={href} className={`nav-link ${active(href) ? 'active' : ''}`} aria-current={active(href) ? 'page' : undefined} onClick={() => setMenuOpen(false)}><Icon size={17} strokeWidth={1.7} />{label}</Link>)}</nav>
      <div className="sidebar-footer"><div className="profile"><span className="profile-avatar">{user.email[0].toUpperCase()}</span><div className="profile-copy"><p title={user.email}>{user.email}</p><small>{user.role}</small></div></div><button className="signout" onClick={() => { localStorage.removeItem('token'); router.replace('/login'); }}><LogOut size={15} />Sign out</button></div>
    </aside>
    <div className="workspace-main"><div className="workspace-topbar"><div className="topbar-title"><button className="menu-toggle" aria-label="Open navigation" aria-controls="workspace-navigation" aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}><Menu size={20} /></button><span>Safety operations</span><ChevronRight size={13} /><span style={{ color: '#172b45' }}>{current?.label || 'Incident details'}</span></div><span className="topbar-detail">Civilian safety workspace</span></div><main id="main-content">{children}</main></div>
  </div>;
}

