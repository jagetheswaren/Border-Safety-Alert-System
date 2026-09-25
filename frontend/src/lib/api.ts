import { AuthResponse, DashboardStats, AppEvent, User, Zone, Incident, Alert, PaginatedResponse, IncidentFilterParams, AlertFilterParams, HealthStatus } from './types';

const API_URL = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1').replace(/\/$/, '');
export const SESSION_EXPIRED = 'bsas:session-expired';

export class ApiError extends Error {
  constructor(message: string, public status: number, public body?: unknown) {
    super(message);
    this.name = 'ApiError';
  }
}
export function isOperator(user: User) {
  return user.is_active && ['ADMIN', 'OPERATOR'].includes(user.role.toUpperCase());
}
async function request(path: string, options: RequestInit = {}, authenticated = true): Promise<Response> {
  const headers = new Headers(options.headers);
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  if (authenticated && token) headers.set('Authorization', `Bearer ${token}`);
  let response: Response;
  try {
    response = await fetch(`${API_URL}${path}`, { ...options, headers, cache: 'no-store', signal: options.signal ?? AbortSignal.timeout(15000) });
  } catch {
    throw new ApiError('The BSAS service could not be reached. Check your connection and try again.', 0);
  }
  if (!response.ok) {
    const body = await response.json().catch(() => null);
    if (response.status === 401 && authenticated && typeof window !== 'undefined') {
      localStorage.removeItem('token');
      window.dispatchEvent(new Event(SESSION_EXPIRED));
    }
    const detail = typeof body?.detail === 'string' ? body.detail : null;
    const message = response.status === 401 ? (authenticated ? 'Your session has expired. Please sign in again.' : 'The email or password was not accepted.')
      : response.status === 403 ? 'Your account does not have permission to access this information.'
      : response.status >= 500 ? 'The BSAS service is unavailable. Please try again shortly.'
      : detail || `The request could not be completed (${response.status}).`;
    throw new ApiError(message, response.status, body);
  }
  return response;
}
export async function login(username: string, password: string): Promise<AuthResponse> {
  return (await request('/auth/login', {
    method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ username, password }),
  }, false)).json();
}
export const fetchWithAuth = (path: string, options: RequestInit = {}) => request(path, options);
export async function getMe(): Promise<User> { return (await request('/auth/me')).json(); }
export async function getDashboardStats(): Promise<DashboardStats> { return (await request('/dashboard/stats')).json(); }
export async function getEvents(since?: string): Promise<AppEvent[]> { return (await request(`/events/poll${since ? `?since=${encodeURIComponent(since)}` : ''}`)).json(); }
export async function getHealth(): Promise<HealthStatus> { return (await request('/health')).json(); }
export async function getZones(): Promise<Zone[]> {
  const zones: Zone[] = [];
  const size = 100;
  // Collect all enabled zones before displaying a total.
  while (true) {
    const page: Zone[] = await (await request(`/zones/?skip=${zones.length}&limit=${size}`)).json();
    zones.push(...page);
    if (page.length < size) return zones;
  }
}
function query(params: IncidentFilterParams | AlertFilterParams) {
  const search = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => { if (value !== undefined && value !== '') search.set(key, String(value)); });
  return search.size ? `?${search}` : '';
}
export async function getIncidents(params: IncidentFilterParams = {}): Promise<PaginatedResponse<Incident>> { return (await request(`/incidents/${query(params)}`)).json(); }
export async function getIncident(id: string): Promise<Incident> { return (await request(`/incidents/${encodeURIComponent(id)}`)).json(); }
export async function getAlerts(params: AlertFilterParams = {}): Promise<PaginatedResponse<Alert>> { return (await request(`/alerts/${query(params)}`)).json(); }

