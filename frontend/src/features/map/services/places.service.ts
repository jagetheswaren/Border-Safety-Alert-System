import { PlaceResult } from '../types/map.types';

let autocompleteService: google.maps.places.AutocompleteService | null = null;
let placesService: google.maps.places.PlacesService | null = null;
let attributionsElement: HTMLDivElement | null = null;

function getAutocompleteService(): google.maps.places.AutocompleteService | null {
  if (typeof window === 'undefined' || !window.google || !window.google.maps || !window.google.maps.places) {
    return null;
  }
  if (!autocompleteService) {
    autocompleteService = new window.google.maps.places.AutocompleteService();
  }
  return autocompleteService;
}

function getPlacesService(): google.maps.places.PlacesService | null {
  if (typeof window === 'undefined' || !window.google || !window.google.maps || !window.google.maps.places) {
    return null;
  }
  if (!placesService) {
    if (!attributionsElement) {
      attributionsElement = document.createElement('div');
    }
    placesService = new window.google.maps.places.PlacesService(attributionsElement);
  }
  return placesService;
}

/**
 * Searches places with query and optional session token.
 */
export async function getPlacePredictions(
  input: string,
  sessionToken?: google.maps.places.AutocompleteSessionToken
): Promise<google.maps.places.AutocompletePrediction[]> {
  const service = getAutocompleteService();
  if (!service || !input.trim()) return [];

  return new Promise((resolve) => {
    service.getPlacePredictions(
      {
        input,
        sessionToken,
        types: ['geocode', 'establishment'],
      },
      (predictions, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK && predictions) {
          resolve(predictions);
        } else {
          resolve([]);
        }
      }
    );
  });
}

/**
 * Fetches place geometry and address by place ID.
 */
export async function fetchPlaceDetails(
  placeId: string,
  sessionToken?: google.maps.places.AutocompleteSessionToken
): Promise<PlaceResult | null> {
  const service = getPlacesService();
  if (!service || !placeId) return null;

  return new Promise((resolve) => {
    service.getDetails(
      {
        placeId,
        fields: ['name', 'formatted_address', 'geometry', 'place_id'],
        sessionToken,
      },
      (place, status) => {
        if (status === google.maps.places.PlacesServiceStatus.OK && place && place.geometry && place.geometry.location) {
          resolve({
            placeId: place.place_id || placeId,
            name: place.name || 'Selected Place',
            formattedAddress: place.formatted_address || '',
            location: {
              lat: place.geometry.location.lat(),
              lng: place.geometry.location.lng(),
            },
          });
        } else {
          resolve(null);
        }
      }
    );
  });
}
