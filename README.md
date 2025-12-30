# PSM Enterprise Cloud Infrastructure

## Virtual Serverless Empire - $0/month

```
╔════════════════════════════════════════════════════════════════════════════╗
║                    PURPLE SQUIRREL MEDIA                                   ║
║                    Global Cloud Mesh Infrastructure                         ║
║                    "Be Everywhere" Edition                                  ║
╚════════════════════════════════════════════════════════════════════════════╝
```

## Architecture Overview

```
                              ┌──────────────┐
                              │   INTERNET   │
                              └──────┬───────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│   CLOUDFLARE  │          │     AZURE     │          │  ORACLE CLOUD │
│   Workers     │◄────────►│   AI + Web    │◄────────►│    Compute    │
│   Pages       │          │   Functions   │          │   Jellyfin    │
│   R2, D1, KV  │          │   CosmosDB    │          │   *arr Stack  │
└───────────────┘          └───────────────┘          └───────────────┘
        │                            │                            │
        └────────────────────────────┼────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│    VERCEL     │          │     AWS       │          │  GOOGLE CLOUD │
│  Edge Funcs   │          │   Lambda      │          │   Functions   │
│  Analytics    │          │   S3, Dynamo  │          │   Firestore   │
└───────────────┘          └───────────────┘          └───────────────┘
        │                            │                            │
        └────────────────────────────┼────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│   SUPABASE    │          │  PLANETSCALE  │          │    UPSTASH    │
│   Database    │          │    MySQL      │          │   Redis/Kafka │
│   Auth/Store  │          │   Serverless  │          │    QStash     │
└───────────────┘          └───────────────┘          └───────────────┘
```

## Cloud Providers (50+ Total)

| Provider | Status | Services | Cost | Free Tier |
|----------|--------|----------|------|-----------|
| **Azure** | ✅ Active | 9 | $0 | F0 AI, Static Apps |
| **Oracle Cloud** | ✅ Online | 4 | $0 | Always Free ARM |
| **Vercel** | ✅ Active | 7 | $0 | Hobby tier |
| **Cloudflare** | 🟡 Pending | 7 | $0 | 100K req/day |
| **AWS** | 🟡 Pending | 9 | $0 | Free tier |
| **Google Cloud** | 🟡 Pending | 7 | $0 | Free tier |
| **Supabase** | 🟡 Pending | 5 | $0 | Free tier |
| **MongoDB Atlas** | 🟡 Pending | 3 | $0 | M0 Free |
| **Netlify** | 🟡 Pending | 4 | $0 | Free tier |
| **Railway** | 🟡 Pending | 1 | $0 | Trial credits |
| **Render** | 🟡 Pending | 4 | $0 | Free tier |
| **PlanetScale** | 🟡 Pending | 1 | $0 | Hobby tier |
| **Upstash** | 🟡 Pending | 4 | $0 | Free tier |
| **+ 38 More** | 🟡 Pending | 100+ | $0 | Various tiers |

**Total: 50 Providers | 150+ Services | $0/month**

### Live Endpoints
- **Azure Website**: https://purplesquirrel.media
- **Vercel Edge API**: https://vercel-dusky-pi.vercel.app/api/status
- **Oracle Jellyfin**: http://163.192.105.31:8096
- **Unified Gateway**: http://localhost:3002

## Quick Start

```bash
# Start everything
./start.sh

# Or individual components:

# Open Command Center
open /Volumes/Virtual\ Server/projects/psm-enterprise/dashboards/command-center.html

# Run Health Check
node services/health-monitor.js

# Start Unified Gateway
node gateway/unified-api.js

# Deploy to Clouds
./deploy-all.sh all

# Activate All Providers
./activate-all.sh
```

## Service Inventory

### Azure (AI + Hosting)
- Vision API (F0) - 5,000/month
- Speech API (F0) - 5 hrs/month  
- Language API (F0) - 5,000/month
- Doc Intelligence (F0) - 500/month
- Translator (F0) - 2M chars/month
- Content Moderator (F0) - 5,000/month
- Static Web Apps - purplesquirrel.media
- Functions (Consumption) - 1M/month
- CosmosDB (Serverless) - 1M RU/month

### Oracle Cloud (Compute)
- ARM Instance (A1.Flex) - 4 OCPU, 24GB RAM
- Jellyfin Media Server
- Traefik Reverse Proxy
- PSM Processor Pipeline
- *arr Stack (Sonarr, Radarr, Prowlarr)

### Cloudflare (Edge)
- Workers - 100K req/day
- Pages - 500 builds/month
- R2 Storage - 10GB
- D1 Database - 5GB
- KV Store - 100K reads/day

### Vercel (Serverless)
- Hosting - 100GB bandwidth
- Edge Functions - 1M invocations
- Analytics - 2.5K events/month

### AWS (Infrastructure)
- Lambda - 1M requests/month
- S3 - 5GB storage
- DynamoDB - 25GB + 25 WCU/RCU
- API Gateway - 1M calls/month
- Cognito - 50K MAU

### Google Cloud (Platform)
- Cloud Functions - 2M invocations
- Firestore - 1GB storage
- Cloud Run - 2M requests
- Cloud Storage - 5GB

### Supabase (Backend)
- PostgreSQL - 500MB
- Auth - 50K MAU
- Storage - 1GB
- Realtime - 200 connections

### Additional Clouds
- **Netlify**: Hosting, Functions, Forms
- **Railway**: Container compute ($5 trial)
- **Render**: Web services (750 hrs/month)
- **PlanetScale**: MySQL (5GB, 1B rows)
- **Upstash**: Redis, Kafka, QStash

## Directory Structure

```
psm-enterprise/
├── dashboards/
│   └── command-center.html    # Executive dashboard
├── gateway/
│   └── unified-api.js         # Multi-cloud API gateway
├── workers/
│   └── cloudflare/            # CF Workers
├── functions/
│   ├── vercel/                # Vercel Edge (LIVE)
│   ├── aws/                   # Lambda
│   └── gcp/                   # Cloud Functions
├── services/
│   └── health-monitor.js      # Health checks
├── config/
│   └── cloud-manifest.json    # All 50 cloud configs
├── start.sh                   # Master startup
├── deploy-all.sh              # Deploy script
├── activate-all.sh            # Provider activation
└── README.md
```

## Monitoring

### Command Center
- Real-time cloud mesh visualization
- Service health matrix (54 services)
- Cost tracking ($0 always)
- Activity feed
- Performance metrics

### Health Monitor
```bash
node services/health-monitor.js
```

## Wallet
- Treasury: `28a1YgoKvSehu7iQLv9uzaWc7pEnS4Qh72cbVmUmQPgw`
- Network: Solana Mainnet

## Links
- Website: https://purplesquirrel.media
- Media: http://163.192.105.31:8096
- Processor: http://localhost:3001

---

*PSM Enterprise v1.0 | Virtual Serverless Empire*
*Total Monthly Cost: $0.00*
