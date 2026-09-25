import { AlertCircle, RefreshCw, Inbox } from 'lucide-react';
import type { ReactNode } from 'react';

export function PageHeader({ eyebrow = 'Safety workspace', title, description, children }: { eyebrow?: string; title: string; description: string; children?: ReactNode }) {
  return <header className="page-header"><div><p className="eyebrow">{eyebrow}</p><h1>{title}</h1><p className="page-description">{description}</p></div><div className="header-actions">{children}</div></header>;
}
export function RefreshButton({ onClick, busy }: { onClick: () => void; busy?: boolean }) {
  return <button className="button button-secondary" onClick={onClick} disabled={busy}><RefreshCw size={15} className={busy ? 'animate-spin' : ''} />Refresh</button>;
}
export function LoadingState({ label = 'Loading information…' }: { label?: string }) {
  return <div className="state" role="status"><RefreshCw size={22} className="animate-spin" /><p>{label}</p></div>;
}
export function ErrorState({ error, retry }: { error: Error; retry: () => void }) {
  return <div className="state error-state" role="alert"><AlertCircle size={25} /><h2>Information unavailable</h2><p>{error.message}</p><button className="button button-secondary" onClick={retry}>Try again</button></div>;
}
export function EmptyState({ title, description }: { title: string; description: string }) {
  return <div className="state"><Inbox size={26} /><h2>{title}</h2><p>{description}</p></div>;
}
export function Badge({ value }: { value: string }) {
  const normalized = value.toUpperCase();
  const tone = ['CRITICAL', 'HIGH', 'RESTRICTED', 'DISCONNECTED', 'DEGRADED', 'UNAVAILABLE'].includes(normalized) ? 'danger'
    : ['WARNING', 'MODERATE', 'MEDIUM', 'CAUTION'].includes(normalized) ? 'warning'
    : ['CONNECTED', 'OK', 'RESOLVED'].includes(normalized) ? 'success' : 'neutral';
  return <span className={`badge badge-${tone}`}>{value.replaceAll('_', ' ')}</span>;
}
export function formatDate(value: string) {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? 'Time unavailable' : date.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

