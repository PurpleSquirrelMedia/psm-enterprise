export const config = { runtime: 'edge' };

const CLOUD_PROVIDERS = {
  azure: { status: 'active', services: 9 },
  oracle: { status: 'active', services: 4 },
  cloudflare: { status: 'active', services: 7 },
  vercel: { status: 'active', services: 7 },
  aws: { status: 'pending', services: 9 },
  gcp: { status: 'pending', services: 7 },
  supabase: { status: 'pending', services: 5 },
  mongodb: { status: 'pending', services: 3 },
  planetscale: { status: 'pending', services: 1 },
  neon: { status: 'pending', services: 2 },
  turso: { status: 'pending', services: 1 },
  upstash: { status: 'pending', services: 4 }
};

export default async function handler(request) {
  const url = new URL(request.url);
  const provider = url.searchParams.get('provider');

  if (provider && CLOUD_PROVIDERS[provider]) {
    return new Response(JSON.stringify({
      provider,
      ...CLOUD_PROVIDERS[provider],
      timestamp: new Date().toISOString()
    }), {
      headers: { 'Content-Type': 'application/json' }
    });
  }

  return new Response(JSON.stringify({
    totalProviders: Object.keys(CLOUD_PROVIDERS).length,
    activeProviders: Object.values(CLOUD_PROVIDERS).filter(p => p.status === 'active').length,
    clouds: CLOUD_PROVIDERS,
    timestamp: new Date().toISOString()
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}
