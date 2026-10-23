import { LatLngLiteral, RouteInfo } from '../types/map.types';

let directionsService: google.maps.DirectionsService | null = null;

function getDirectionsService(): google.maps.DirectionsService | null {
  if (typeof window === 'undefined' || !window.google || !window.google.maps) {
    return null;
  }
  if (!directionsService) {
    directionsService = new window.google.maps.DirectionsService();
  }
  return directionsService;
}

export async function calculateRoute(
  origin: LatLngLiteral,
  destination: LatLngLiteral,
  travelMode: google.maps.TravelMode = google.maps.TravelMode.DRIVING
): Promise<RouteInfo | null> {
  const service = getDirectionsService();
  if (!service) return null;

  return new Promise((resolve) => {
    service.route(
      {
        origin: new google.maps.LatLng(origin.lat, origin.lng),
        destination: new google.maps.LatLng(destination.lat, destination.lng),
        travelMode,
      },
      (result, status) => {
        if (status === google.maps.DirectionsStatus.OK && result && result.routes && result.routes.length > 0) {
          const route = result.routes[0];
          const leg = route.legs[0];

          const polylinePath: LatLngLiteral[] = [];
          if (route.overview_path) {
            route.overview_path.forEach((pt) => {
              polylinePath.push({ lat: pt.lat(), lng: pt.lng() });
            });
          }

          resolve({
            origin,
            destination,
            originName: leg?.start_address,
            destinationName: leg?.end_address,
            distanceMeters: leg?.distance?.value || 0,
            distanceText: leg?.distance?.text || '0 km',
            durationSeconds: leg?.duration?.value || 0,
            durationText: leg?.duration?.text || '0 mins',
            polylinePath,
          });
        } else {
          console.error('Directions request failed with status:', status);
          resolve(null);
        }
      }
    );
  });
}
