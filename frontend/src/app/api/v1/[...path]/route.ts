import { NextRequest } from 'next/server';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 200;

async function proxy(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const { path } = await context.params;
  if (path.some(segment => segment === '..' || segment === '.' || !/^[\w.-]+$/.test(segment))) return Response.json({ detail: 'Invalid API path' }, { status: 400 });
  const base = (process.env.BSAS_BACKEND_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
  const url = `${base}/api/v1/${path.join('/')}${request.nextUrl.search}`;
  const headers = new Headers();
  for (const key of ['authorization', 'content-type', 'accept']) {
    const value = request.headers.get(key);
    if (value) headers.set(key, value);
  }
  try {
    const upstream = await fetch(url, {
      method: request.method, headers,
      body: ['GET', 'HEAD'].includes(request.method) ? undefined : await request.arrayBuffer(),
      cache: 'no-store', signal: AbortSignal.timeout(190000),
    });
    return new Response(upstream.body, { status: upstream.status, headers: {
      'Content-Type': upstream.headers.get('content-type') || 'application/json',
      'Cache-Control': 'no-store',
    } });
  } catch {
    return Response.json({ detail: 'The BSAS backend is unavailable. Start the backend and retry.' }, { status: 502, headers: { 'Cache-Control': 'no-store' } });
  }
}

export { proxy as GET, proxy as POST, proxy as PATCH, proxy as PUT, proxy as DELETE };
