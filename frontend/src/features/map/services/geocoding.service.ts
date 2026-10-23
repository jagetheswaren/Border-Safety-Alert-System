import { LatLngLiteral } from '../types/map.types';

let geocoder: google.maps.Geocoder | null = null;

function getGeocoder(): google.maps.Geocoder | null {
  if (typeof window === 'undefined' || !window.google || !window.google.maps) {
    return null;
  }
  if (!geocoder) {
    geocoder = new window.google.maps.Geocoder();
  }
  return geocoder;
}

export async function reverseGeocode(location: LatLngLiteral): Promise<string> {
  const coder = getGeocoder();
  if (!coder) return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;

  return new Promise((resolve) => {
    coder.geocode({ location }, (results, status) => {
      if (status === google.maps.GeocoderStatus.OK && results && results.length > 0) {
        resolve(results[0].formatted_address);
      } else {
        resolve(`${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`);
      }
    });
  });
}
