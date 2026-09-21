import { 
  AuthResponse, 
  DashboardStats, 
  AppEvent, 
  User, 
  Zone, 
  Incident, 
  Alert, 
  PaginatedResponse,
  IncidentFilterParams,
  AlertFilterParams 
} from './types';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';

export async function login(username: string, password: string = "password"): Promise<AuthResponse> {
  const formData = new URLSearchParams();
  formData.append('username', username);
  formData.append('password', password);

  const res = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: formData,
  });

  if (!res.ok) {
    throw new Error('Login failed');
  }

  return res.json();
}

export async function fetchWithAuth(url: string, options: RequestInit = {}) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null;
  const headers = new Headers(options.headers || {});
  
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  const res = await fetch(`${API_URL}${url}`, { ...options, headers });
  
  if (res.status === 401) {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('token');
    }
    throw new Error('Unauthorized');
  }
  
  return res;
}

export async function getMe(): Promise<User> {
  const res = await fetchWithAuth('/auth/me');
  return res.json();
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const res = await fetchWithAuth('/dashboard/stats');
  return res.json();
}

export async function getEvents(since?: string): Promise<AppEvent[]> {
  const query = since ? `?since=${encodeURIComponent(since)}` : '';
  const res = await fetchWithAuth(`/events/poll${query}`);
  return res.json();
}

export async function getZones(): Promise<Zone[]> {
  const res = await fetchWithAuth('/zones/');
  return res.json();
}

export async function getIncidents(params: IncidentFilterParams = {}): Promise<PaginatedResponse<Incident>> {
  const searchParams = new URLSearchParams();
  if (params.skip !== undefined) searchParams.append('skip', params.skip.toString());
  if (params.limit !== undefined) searchParams.append('limit', params.limit.toString());
  if (params.search) searchParams.append('search', params.search);
  if (params.severity) searchParams.append('severity', params.severity);
  if (params.status) searchParams.append('status', params.status);
  if (params.category) searchParams.append('category', params.category);
  if (params.zone_id) searchParams.append('zone_id', params.zone_id);

  const queryString = searchParams.toString() ? `?${searchParams.toString()}` : '';
  const res = await fetchWithAuth(`/incidents/${queryString}`);
  if (!res.ok) {
    throw new Error('Failed to fetch incidents');
  }
  return res.json();
}

export async function getIncident(id: string): Promise<Incident> {
  const res = await fetchWithAuth(`/incidents/${id}`);
  if (!res.ok) {
    if (res.status === 404) throw new Error('Incident not found');
    throw new Error('Failed to fetch incident details');
  }
  return res.json();
}

export async function getAlerts(params: AlertFilterParams = {}): Promise<PaginatedResponse<Alert>> {
  const searchParams = new URLSearchParams();
  if (params.skip !== undefined) searchParams.append('skip', params.skip.toString());
  if (params.limit !== undefined) searchParams.append('limit', params.limit.toString());
  if (params.search) searchParams.append('search', params.search);
  if (params.type) searchParams.append('type', params.type);
  if (params.severity) searchParams.append('severity', params.severity);
  if (params.zone_id) searchParams.append('zone_id', params.zone_id);

  const queryString = searchParams.toString() ? `?${searchParams.toString()}` : '';
  const res = await fetchWithAuth(`/alerts/${queryString}`);
  if (!res.ok) {
    throw new Error('Failed to fetch alerts');
  }
  return res.json();
}
