import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Border Safety Alert System', short_name: 'BSAS',
    description: 'Live maps, device location, safety monitoring and AI assistance.',
    start_url: '/dashboard/map', scope: '/', display: 'standalone',
    background_color: '#090d16', theme_color: '#090d16',
    icons: [192, 512].map(size => ({ src: `/icons/bsas-${size}.png`, sizes: `${size}x${size}`, type: 'image/png', purpose: 'any' })),
  };
}
