export const config = { runtime: 'edge' };

export default async function handler(request) {
  const checks = {
    vercel: true,
    memory: process.memoryUsage ? 'available' : 'edge',
    region: process.env.VERCEL_REGION || 'unknown',
  };

  return new Response(JSON.stringify({
    status: 'healthy',
    checks,
    timestamp: new Date().toISOString()
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}
