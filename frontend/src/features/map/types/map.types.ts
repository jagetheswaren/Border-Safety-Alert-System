export type MapProvider = 'google' | 'offline';

export type MapTypeMode = 'roadmap' | 'satellite' | 'hybrid' | 'terrain';

export interface LatLngLiteral {
  lat: number;
  lng: number;
}

export interface BorderProperties {
  id: string;
  boundary_name: string;
  region_a?: string;
  region_b?: string;
  source?: string;
  source_date?: string;
  boundary_type?: string;
  risk_level?: 'SAFE' | 'AWARENESS' | 'WARNING' | 'CRITICAL';
  description?: string;
}

export interface BorderFeature {
  type: 'Feature';
  id: string;
  properties: BorderProperties;
  geometry: {
    type: 'LineString' | 'MultiLineString' | 'Polygon' | 'MultiPolygon';
    coordinates: number[] | number[][] | number[][][] | number[][][][];
  };
}

export interface BorderFeatureCollection {
  type: 'FeatureCollection';
  metadata: {
    source?: string;
    version?: string;
    authority?: string;
    updated_at?: string;
    [key: string]: unknown;
  };
  features: BorderFeature[];
}

export interface SafetyZoneConfig {
  awarenessMeters: number;
  warningMeters: number;
  criticalMeters: number;
}

export interface SafetyZoneFeature {
  id: string;
  name: string;
  zone_type: 'SAFE' | 'AWARENESS' | 'WARNING' | 'CRITICAL';
  severity: string;
  safety_level?: string;
  color: string;
  fillOpacity: number;
  warning_radius_m: number;
  description?: string;
  coordinates: [number, number][]; // [lat, lng] array
  rings?: [number, number][][];
}

export interface PlaceResult {
  placeId: string;
  name: string;
  formattedAddress: string;
  location: LatLngLiteral;
}

export interface RouteInfo {
  origin: LatLngLiteral;
  destination: LatLngLiteral;
  originName?: string;
  destinationName?: string;
  distanceMeters: number;
  distanceText: string;
  durationSeconds: number;
  durationText: string;
  polylinePath: LatLngLiteral[];
}

export interface IncidentMarkerItem {
  id: string;
  incidentNumber?: string;
  title: string;
  category: string;
  severity: string;
  status: string;
  latitude: number;
  longitude: number;
  description?: string;
  reportedBy?: string;
  assignedTo?: string;
  createdAt: string;
}

export interface DeviceMarkerItem {
  id: string;
  deviceId: string;
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  heading?: number;
  timestamp: string;
  status?: string;
}

export interface UserLocationState {
  coords: LatLngLiteral | null;
  accuracy: number | null;
  heading: number | null;
  speed: number | null;
  timestamp: number | null;
  isLoading: boolean;
  error: string | null;
  permissionDenied: boolean;
}

export interface MapLayersVisibility {
  borders: boolean;
  safetyZones: boolean;
  incidents: boolean;
  devices: boolean;
  traffic: boolean;
  route: boolean;
  legend: boolean;
}

export interface StreetViewState {
  isOpen: boolean;
  position: LatLngLiteral | null;
  available: boolean | null;
  heading: number;
  pitch: number;
  zoom: number;
}
