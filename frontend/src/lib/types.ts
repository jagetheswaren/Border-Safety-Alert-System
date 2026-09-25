export interface User {
  id: string;
  email: string;
  role: string;
  is_active: boolean;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
}

export interface DashboardStats {
  active_users: number;
  open_incidents: number;
  critical_alerts: number;
  current_risk: string;
}

export interface AppEvent {
  id: string;
  type: "INCIDENT" | "ALERT";
  title: string;
  severity: string;
  timestamp: string;
  data: string;
}

export interface GeoJSONGeometry {
  type: string;
  coordinates: number[][][] | number[][][][] | number[];
}

export interface Zone {
  id: string;
  name: string;
  type: string;
  severity: string;
  geometry: string | GeoJSONGeometry;
  warning_radius_m?: number;
  enabled?: boolean;
  version?: string;
  created_at: string;
  updated_at?: string;
}

export interface Incident {
  id: string;
  incident_number?: string;
  title: string;
  description?: string;
  category: string;
  severity: string;
  status: string;
  latitude?: number;
  longitude?: number;
  zone_id?: string;
  reported_by?: string;
  assigned_to?: string;
  ai_summary?: string;
  created_at: string;
  updated_at?: string;
  resolved_at?: string;
}

export interface Alert {
  id: string;
  type: string;
  severity: string;
  title: string;
  message: string;
  user_id?: string;
  device_id?: string;
  zone_id?: string;
  incident_id?: string;
  location_lat?: number;
  location_lng?: number;
  created_at: string;
  acknowledged_at?: string;
  resolved_at?: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
}

export interface IncidentFilterParams {
  skip?: number;
  limit?: number;
  search?: string;
  severity?: string;
  status?: string;
  category?: string;
  zone_id?: string;
}

export interface AlertFilterParams {
  skip?: number;
  limit?: number;
  search?: string;
  type?: string;
  severity?: string;
  zone_id?: string;
}

export interface HealthStatus {
  status: string;
  service: string;
  version: string;
  environment: string;
  database: { status: string; engine: string; geospatial: string };
}
