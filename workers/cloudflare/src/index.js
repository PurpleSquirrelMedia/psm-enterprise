/**
 * PSM Global API - Cloudflare Workers
 * Edge computing for Purple Squirrel Media
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    };
    
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }
    
    // API routes
    if (path === '/api/status') {
      return Response.json({
        service: 'PSM Global API',
        provider: 'Cloudflare Workers',
        region: request.cf?.colo || 'unknown',
        version: env.PSM_VERSION,
        timestamp: new Date().toISOString(),
        status: 'operational',
        latency: Date.now() - request.cf?.clientTcpRtt || 0
      }, { headers: corsHeaders });
    }
    
    if (path === '/api/geo') {
      return Response.json({
        ip: request.headers.get('CF-Connecting-IP'),
        country: request.cf?.country,
        city: request.cf?.city,
        region: request.cf?.region,
        colo: request.cf?.colo,
        timezone: request.cf?.timezone
      }, { headers: corsHeaders });
    }
    
    if (path === '/api/health') {
      return Response.json({
        clouds: {
          cloudflare: { status: 'active', latency: 1 },
          azure: { status: 'active', latency: 45 },
          oracle: { status: 'offline', latency: null },
          vercel: { status: 'pending', latency: null },
          aws: { status: 'pending', latency: null },
          gcp: { status: 'pending', latency: null }
        },
        overall: 'degraded',
        timestamp: new Date().toISOString()
      }, { headers: corsHeaders });
    }
    
    if (path === '/') {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>PSM Global API</title>
          <style>
            body { font-family: system-ui; background: #0a0a0f; color: #e0e0f0; padding: 2rem; }
            h1 { color: #8b5cf6; }
            code { background: #1a1a2e; padding: 0.5rem 1rem; border-radius: 4px; display: block; margin: 1rem 0; }
          </style>
        </head>
        <body>
          <h1>🟣 PSM Global API</h1>
          <p>Powered by Cloudflare Workers @ Edge</p>
          <h3>Endpoints:</h3>
          <code>GET /api/status - Service status</code>
          <code>GET /api/geo - Geo information</code>
          <code>GET /api/health - Multi-cloud health</code>
        </body>
        </html>
      `, { 
        headers: { 
          'Content-Type': 'text/html',
          ...corsHeaders 
        } 
      });
    }
    
    return Response.json({ error: 'Not found' }, { status: 404, headers: corsHeaders });
  }
};
