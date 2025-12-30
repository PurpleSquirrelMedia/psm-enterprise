#!/usr/bin/env node
/**
 * PSM Enterprise Unified API Gateway
 * Aggregates all cloud provider APIs into a single interface
 */

const http = require('http');
const https = require('https');
const url = require('url');

const PORT = process.env.PORT || 3002;

// Cloud Provider Endpoints
const ENDPOINTS = {
  azure: {
    website: 'https://purplesquirrel.media',
    vision: 'https://eastus.api.cognitive.microsoft.com/vision/v3.2',
    speech: 'https://eastus.api.cognitive.microsoft.com/speechtotext/v3.1',
    language: 'https://eastus.api.cognitive.microsoft.com/language',
    docint: 'https://eastus.api.cognitive.microsoft.com/formrecognizer/v2.1',
    translator: 'https://api.cognitive.microsofttranslator.com'
  },
  oracle: {
    jellyfin: 'http://163.192.105.31:8096',
    traefik: 'http://163.192.105.31:8080'
  },
  vercel: {
    status: 'https://vercel-dusky-pi.vercel.app/api/status',
    health: 'https://vercel-dusky-pi.vercel.app/api/health',
    clouds: 'https://vercel-dusky-pi.vercel.app/api/clouds'
  },
  cloudflare: {
    // Workers will be active once subdomain is registered
    workers: 'https://psm-api.purplesquirrel.workers.dev'
  }
};

const colors = {
  purple: '\x1b[35m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

// Fetch helper with timeout
async function fetchWithTimeout(urlStr, options = {}, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const protocol = urlStr.startsWith('https') ? https : http;
    const parsed = new url.URL(urlStr);

    const req = protocol.get({
      hostname: parsed.hostname,
      port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
      path: parsed.pathname + parsed.search,
      timeout,
      headers: options.headers || {}
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({
            status: res.statusCode,
            data: JSON.parse(data),
            headers: res.headers
          });
        } catch {
          resolve({ status: res.statusCode, data, headers: res.headers });
        }
      });
    });

    req.on('error', err => reject(err));
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

// Check all cloud health
async function checkAllHealth() {
  const results = {};

  for (const [cloud, endpoints] of Object.entries(ENDPOINTS)) {
    results[cloud] = {};
    for (const [name, endpoint] of Object.entries(endpoints)) {
      try {
        const start = Date.now();
        await fetchWithTimeout(endpoint, {}, 5000);
        results[cloud][name] = {
          status: 'online',
          latency: Date.now() - start
        };
      } catch {
        results[cloud][name] = { status: 'offline', latency: null };
      }
    }
  }

  return results;
}

// Request handler
async function handleRequest(req, res) {
  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    // Routes
    if (path === '/api/status' || path === '/') {
      res.writeHead(200);
      res.end(JSON.stringify({
        service: 'PSM Unified API Gateway',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        status: 'operational',
        providers: Object.keys(ENDPOINTS).length,
        endpoints: Object.values(ENDPOINTS).reduce((a, b) => a + Object.keys(b).length, 0)
      }));
      return;
    }

    if (path === '/api/health') {
      const health = await checkAllHealth();
      const total = Object.values(health).reduce((a, cloud) =>
        a + Object.keys(cloud).length, 0);
      const online = Object.values(health).reduce((a, cloud) =>
        a + Object.values(cloud).filter(s => s.status === 'online').length, 0);

      res.writeHead(200);
      res.end(JSON.stringify({
        status: online === total ? 'healthy' : online > 0 ? 'degraded' : 'unhealthy',
        uptime: `${Math.round((online / total) * 100)}%`,
        online,
        total,
        clouds: health,
        timestamp: new Date().toISOString()
      }));
      return;
    }

    if (path === '/api/clouds') {
      res.writeHead(200);
      res.end(JSON.stringify({
        providers: ENDPOINTS,
        totalProviders: Object.keys(ENDPOINTS).length,
        totalEndpoints: Object.values(ENDPOINTS).reduce((a, b) => a + Object.keys(b).length, 0),
        timestamp: new Date().toISOString()
      }));
      return;
    }

    if (path === '/api/vercel/status') {
      try {
        const result = await fetchWithTimeout(ENDPOINTS.vercel.status);
        res.writeHead(200);
        res.end(JSON.stringify(result.data));
      } catch (err) {
        res.writeHead(502);
        res.end(JSON.stringify({ error: 'Vercel unavailable', message: err.message }));
      }
      return;
    }

    if (path === '/api/oracle/health') {
      try {
        const result = await fetchWithTimeout(ENDPOINTS.oracle.jellyfin + '/health');
        res.writeHead(200);
        res.end(JSON.stringify(result.data));
      } catch (err) {
        res.writeHead(502);
        res.end(JSON.stringify({ error: 'Oracle unavailable', message: err.message }));
      }
      return;
    }

    // 404
    res.writeHead(404);
    res.end(JSON.stringify({
      error: 'Not Found',
      path,
      availableRoutes: [
        '/api/status',
        '/api/health',
        '/api/clouds',
        '/api/vercel/status',
        '/api/oracle/health'
      ]
    }));

  } catch (err) {
    res.writeHead(500);
    res.end(JSON.stringify({ error: 'Internal Server Error', message: err.message }));
  }
}

// Start server
const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log(`${colors.purple}${colors.bold}`);
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     PSM UNIFIED API GATEWAY                                ║');
  console.log('║     Multi-Cloud Aggregation Layer                          ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log(`${colors.reset}`);
  console.log(`${colors.cyan}Server running at:${colors.reset} http://localhost:${PORT}`);
  console.log(`${colors.cyan}Providers:${colors.reset} ${Object.keys(ENDPOINTS).join(', ')}`);
  console.log(`${colors.cyan}Total Endpoints:${colors.reset} ${Object.values(ENDPOINTS).reduce((a, b) => a + Object.keys(b).length, 0)}`);
  console.log('');
  console.log('Routes:');
  console.log('  GET /api/status  - Gateway status');
  console.log('  GET /api/health  - All cloud health');
  console.log('  GET /api/clouds  - Provider listing');
  console.log('');
});

module.exports = { server, ENDPOINTS, checkAllHealth };
