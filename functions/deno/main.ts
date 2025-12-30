// PSM Enterprise - Deno Deploy Edge Functions
// Deploy: deployctl deploy --project=psm-api main.ts

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Content-Type": "application/json",
};

const CLOUD_MESH = {
  azure: { status: "active", services: 9, url: "https://purplesquirrel.media" },
  oracle: { status: "active", services: 4, url: "http://163.192.105.31:8096" },
  vercel: { status: "active", services: 7, url: "https://vercel-dusky-pi.vercel.app" },
  cloudflare: { status: "pending", services: 7 },
  netlify: { status: "active", services: 4 },
  deno: { status: "active", services: 2 },
  aws: { status: "pending", services: 9 },
  gcp: { status: "pending", services: 7 },
};

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const path = url.pathname;

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Routes
  if (path === "/" || path === "/api/status") {
    return new Response(JSON.stringify({
      service: "PSM Edge Functions",
      provider: "Deno Deploy",
      region: Deno.env.get("DENO_REGION") || "global",
      version: "1.0.0",
      timestamp: new Date().toISOString(),
      status: "operational",
      runtime: `Deno ${Deno.version.deno}`,
    }), { headers: CORS_HEADERS });
  }

  if (path === "/api/health") {
    return new Response(JSON.stringify({
      status: "healthy",
      memory: Deno.memoryUsage(),
      timestamp: new Date().toISOString(),
    }), { headers: CORS_HEADERS });
  }

  if (path === "/api/clouds") {
    return new Response(JSON.stringify({
      totalProviders: Object.keys(CLOUD_MESH).length,
      activeProviders: Object.values(CLOUD_MESH).filter(c => c.status === "active").length,
      clouds: CLOUD_MESH,
      timestamp: new Date().toISOString(),
    }), { headers: CORS_HEADERS });
  }

  if (path === "/api/mesh/health") {
    // Check all cloud endpoints
    const results: Record<string, unknown> = {};

    for (const [name, cloud] of Object.entries(CLOUD_MESH)) {
      if (cloud.url) {
        try {
          const start = Date.now();
          const res = await fetch(cloud.url, {
            signal: AbortSignal.timeout(5000)
          });
          results[name] = {
            status: res.ok ? "online" : "error",
            latency: Date.now() - start,
            code: res.status,
          };
        } catch {
          results[name] = { status: "offline", latency: null };
        }
      } else {
        results[name] = { status: cloud.status };
      }
    }

    const online = Object.values(results).filter(
      (r: any) => r.status === "online" || r.status === "active"
    ).length;

    return new Response(JSON.stringify({
      uptime: `${Math.round((online / Object.keys(results).length) * 100)}%`,
      online,
      total: Object.keys(results).length,
      clouds: results,
      timestamp: new Date().toISOString(),
    }), { headers: CORS_HEADERS });
  }

  // 404
  return new Response(JSON.stringify({
    error: "Not Found",
    path,
    routes: ["/api/status", "/api/health", "/api/clouds", "/api/mesh/health"],
  }), { status: 404, headers: CORS_HEADERS });
});
