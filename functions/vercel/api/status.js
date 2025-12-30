/**
 * PSM Status API - Vercel Edge Functions
 */

export const config = {
  runtime: 'edge',
};

export default async function handler(request) {
  return new Response(JSON.stringify({
    service: 'PSM Edge Functions',
    provider: 'Vercel',
    region: process.env.VERCEL_REGION || 'unknown',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    status: 'operational'
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*'
    }
  });
}
