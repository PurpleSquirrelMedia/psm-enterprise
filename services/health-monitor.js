#!/usr/bin/env node
/**
 * PSM Enterprise Health Monitor
 * Checks all cloud services and reports status
 */

const https = require('https');
const http = require('http');

const ENDPOINTS = {
  azure: {
    website: 'https://purplesquirrel.media',
    vision: 'https://eastus.api.cognitive.microsoft.com/vision/v3.2/models',
  },
  oracle: {
    server: 'http://163.192.105.31:8096/health',
  },
  cloudflare: {
    pages: 'https://psm-dashboard.pages.dev',
    workers: 'https://psm-api.purplesquirrelnetworks.workers.dev/api/status',
  },
  vercel: {
    functions: 'https://vercel-dusky-pi.vercel.app/api/status',
    health: 'https://vercel-dusky-pi.vercel.app/api/health',
  },
  netlify: {
    functions: 'https://psm-enterprise.netlify.app/api/status',
    clouds: 'https://psm-enterprise.netlify.app/api/clouds',
  },
  gcp: {
    functions: 'https://us-central1-gmail-481217.cloudfunctions.net/psm-status',
  },
  ibm: {
    bridge: 'https://psm-bridge.24izjue4x2ll.us-south.codeengine.appdomain.cloud',
    ai: 'https://psm-ai.24izjue4x2ll.us-south.codeengine.appdomain.cloud',
    events: 'https://psm-events.24izjue4x2ll.us-south.codeengine.appdomain.cloud',
  },
  github: {
    pages: 'https://purplesquirrelmedia.github.io/psm-enterprise/',
  },
  local: {
    processor: 'http://localhost:3001/api/status',
    gateway: 'http://localhost:3002/api/status',
  }
};

const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  purple: '\x1b[35m',
  cyan: '\x1b[36m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

async function checkEndpoint(url, timeout = 5000) {
  return new Promise((resolve) => {
    const start = Date.now();
    const protocol = url.startsWith('https') ? https : http;
    
    const req = protocol.get(url, { timeout }, (res) => {
      const latency = Date.now() - start;
      resolve({
        status: res.statusCode >= 200 && res.statusCode < 400 ? 'online' : 'error',
        code: res.statusCode,
        latency
      });
    });
    
    req.on('error', () => resolve({ status: 'offline', code: 0, latency: null }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ status: 'timeout', code: 0, latency: timeout });
    });
  });
}

async function runHealthCheck() {
  console.log(`${colors.purple}${colors.bold}`);
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║     PSM ENTERPRISE HEALTH MONITOR                          ║');
  console.log('╚════════════════════════════════════════════════════════════╝');
  console.log(`${colors.reset}`);
  console.log(`Time: ${new Date().toISOString()}\n`);
  
  const results = {};
  let onlineCount = 0;
  let totalCount = 0;
  
  for (const [cloud, endpoints] of Object.entries(ENDPOINTS)) {
    console.log(`${colors.cyan}[${cloud.toUpperCase()}]${colors.reset}`);
    results[cloud] = {};
    
    for (const [name, url] of Object.entries(endpoints)) {
      totalCount++;
      process.stdout.write(`  ${name}: `);
      
      const result = await checkEndpoint(url);
      results[cloud][name] = result;
      
      if (result.status === 'online') {
        onlineCount++;
        console.log(`${colors.green}ONLINE${colors.reset} (${result.latency}ms)`);
      } else if (result.status === 'timeout') {
        console.log(`${colors.yellow}TIMEOUT${colors.reset}`);
      } else {
        console.log(`${colors.red}OFFLINE${colors.reset}`);
      }
    }
    console.log();
  }
  
  // Summary
  const healthPercent = Math.round((onlineCount / totalCount) * 100);
  console.log(`${colors.purple}═══════════════════════════════════════════${colors.reset}`);
  console.log(`Overall Health: ${healthPercent >= 80 ? colors.green : healthPercent >= 50 ? colors.yellow : colors.red}${healthPercent}%${colors.reset}`);
  console.log(`Services Online: ${onlineCount}/${totalCount}`);
  console.log(`${colors.purple}═══════════════════════════════════════════${colors.reset}\n`);
  
  return results;
}

// Run if called directly
if (require.main === module) {
  runHealthCheck().catch(console.error);
}

module.exports = { runHealthCheck, checkEndpoint };
