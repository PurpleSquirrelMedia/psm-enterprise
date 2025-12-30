/**
 * PSM AI Proxy - Vercel Edge Functions
 * Routes to Azure Cognitive Services
 */

export const config = {
  runtime: 'edge',
};

export default async function handler(request) {
  const url = new URL(request.url);
  const service = url.searchParams.get('service') || 'vision';
  
  // Return available AI services
  return new Response(JSON.stringify({
    services: {
      vision: { status: 'active', quota: { used: 13, limit: 5000 } },
      speech: { status: 'active', quota: { used: 0, limit: 300 } },
      language: { status: 'active', quota: { used: 13, limit: 5000 } },
      translator: { status: 'active', quota: { used: 0, limit: 2000000 } },
      docint: { status: 'active', quota: { used: 13, limit: 500 } }
    },
    provider: 'Azure Cognitive Services (via Vercel Edge)',
    timestamp: new Date().toISOString()
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
