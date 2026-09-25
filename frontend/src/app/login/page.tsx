"use client";
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { ShieldCheck, ArrowRight, LockKeyhole } from 'lucide-react';
import { login, getMe, isOperator } from '@/lib/api';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  useEffect(() => {
    const reason = new URLSearchParams(window.location.search).get('reason');
    // Defer to keep the initial render identical on the server and browser.
    queueMicrotask(() => {
      if (reason === 'expired') setError('Your session has expired. Please sign in again.');
      if (reason === 'role') setError('Dashboard access requires an active ADMIN or OPERATOR account. Field users should use the BSAS mobile app.');
    });
  }, []);
  const submit = async (event: React.FormEvent) => {
    event.preventDefault(); setLoading(true); setError('');
    try {
      const response = await login(email.trim(), password);
      localStorage.setItem('token', response.access_token);
      const user = await getMe();
      if (!isOperator(user)) throw new Error('Dashboard access requires an active ADMIN or OPERATOR account. Field users should use the BSAS mobile app.');
      router.replace('/dashboard');
    } catch (error) {
      localStorage.removeItem('token');
      setError(error instanceof Error ? error.message : 'Unable to sign in.');
    } finally { setLoading(false); }
  };
  return <div className="auth-page">
    <aside className="auth-aside"><div className="brand"><span className="brand-icon"><ShieldCheck size={25} /></span><span><strong>BSAS</strong><small>BORDER SAFETY ALERT SYSTEM</small></span></div><div><div className="eyebrow">Awareness. Coordination. Care.</div><h1>A clearer view.<br />A safer journey.</h1><p>A shared workspace for the people who help keep communities informed and safe.</p></div><footer>Border Safety Alert System · Operations workspace</footer></aside>
    <main className="auth-content"><div className="auth-form"><div className="auth-brand-mobile"><ShieldCheck size={25} />BSAS</div><p className="eyebrow">Operations workspace</p><h1>Welcome back</h1><p className="page-description">Sign in to view safety zones, alerts, and incident reports.</p>{error && <div className="auth-error" role="alert">{error}</div>}
      <form onSubmit={submit}><div><label htmlFor="email">Email address</label><input className="input" id="email" type="email" autoComplete="username" placeholder="you@organisation.org" required value={email} onChange={event => setEmail(event.target.value)} disabled={loading} /></div><div><label htmlFor="password">Password</label><input className="input" id="password" type="password" autoComplete="current-password" placeholder="Enter your password" required value={password} onChange={event => setPassword(event.target.value)} disabled={loading} /></div><button className="button button-primary" type="submit" disabled={loading}>{loading ? 'Signing in…' : 'Sign in to workspace'}{!loading && <ArrowRight size={16} />}</button></form>
      <p className="auth-footnote"><LockKeyhole size={13} style={{ display: 'inline', marginRight: 6 }} />For authorised administrators and operators.<br />Need access? Contact your BSAS administrator.</p>
    </div></main>
  </div>;
}

