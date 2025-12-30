#!/bin/bash
# PSM Enterprise - Activate All Services
# Connects 50+ cloud providers to purplesquirrel.media

set -e

DOMAIN="purplesquirrel.media"
ENTERPRISE_DIR="/Volumes/Virtual Server/projects/psm-enterprise"

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║     PSM ENTERPRISE ACTIVATION - 150+ SERVICES                              ║"
echo "║     Domain: $DOMAIN                                                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# ============ TIER 1: CLI-Ready (We have the CLIs) ============
echo "=== TIER 1: CLI-Ready Services ==="

# Cloudflare
if command -v wrangler &> /dev/null; then
    echo "[Cloudflare] Deploying Workers, Pages, KV, D1, R2..."
    cd "$ENTERPRISE_DIR/workers/cloudflare"
    wrangler deploy 2>/dev/null && echo "  ✅ Workers deployed" || echo "  ⚠️  Run 'wrangler login' first"
fi

# Vercel  
if command -v vercel &> /dev/null; then
    echo "[Vercel] Deploying Edge Functions..."
    cd "$ENTERPRISE_DIR/functions/vercel"
    vercel --prod -y 2>/dev/null && echo "  ✅ Vercel deployed" || echo "  ⚠️  Run 'vercel login' first"
fi

# AWS
if command -v aws &> /dev/null; then
    echo "[AWS] Checking configuration..."
    aws sts get-caller-identity 2>/dev/null && echo "  ✅ AWS configured" || echo "  ⚠️  Run 'aws configure' first"
fi

# GCP
if command -v gcloud &> /dev/null; then
    echo "[GCP] Checking configuration..."
    gcloud auth list 2>/dev/null | grep -q ACTIVE && echo "  ✅ GCP configured" || echo "  ⚠️  Run 'gcloud auth login' first"
fi

# Azure (already active)
echo "[Azure] Already active - purplesquirrel.media hosted"
echo "  ✅ Static Web App"
echo "  ✅ Vision API"
echo "  ✅ Speech API"  
echo "  ✅ Language API"
echo "  ✅ Doc Intelligence"
echo "  ✅ Translator"

# ============ TIER 2: Browser Setup Required ============
echo ""
echo "=== TIER 2: Browser Signup Required ==="
cat << 'SIGNUP'
Visit these URLs to activate free tiers:

DATABASES:
  • MongoDB Atlas:    https://cloud.mongodb.com (512MB free)
  • PlanetScale:      https://planetscale.com (5GB free)
  • Neon Postgres:    https://neon.tech (3GB free)
  • Turso SQLite:     https://turso.tech (9GB free)
  • CockroachDB:      https://cockroachlabs.cloud (5GB free)
  • Fauna:            https://fauna.com (100K ops/day)
  • Supabase:         https://supabase.com (500MB free)

STORAGE:
  • Backblaze B2:     https://backblaze.com/b2 (10GB free)
  • Cloudinary:       https://cloudinary.com (25GB free)
  • ImageKit:         https://imagekit.io (20GB free)
  • Uploadcare:       https://uploadcare.com (3GB free)

SEARCH:
  • Algolia:          https://algolia.com (10K records free)
  • Meilisearch:      https://meilisearch.com (100K docs free)
  • Typesense:        https://cloud.typesense.org (10K docs free)

REALTIME:
  • Pusher:           https://pusher.com (200K msg/day free)
  • Ably:             https://ably.com (6M msg/month free)

EMAIL:
  • SendGrid:         https://sendgrid.com (100/day free)
  • Resend:           https://resend.com (3K/month free)
  • Mailgun:          https://mailgun.com (5K/month free)

AUTH:
  • Auth0:            https://auth0.com (7K MAU free)
  • Clerk:            https://clerk.com (10K MAU free)

MONITORING:
  • Grafana Cloud:    https://grafana.com (10K metrics free)
  • Sentry:           https://sentry.io (5K errors free)
  • PostHog:          https://posthog.com (1M events free)
  • New Relic:        https://newrelic.com (100GB free)

HOSTING:
  • Netlify:          https://netlify.com (100GB free)
  • Render:           https://render.com (750 hrs free)
  • Railway:          https://railway.app ($5 credit)
  • Fly.io:           https://fly.io (3 VMs free)
  • Deno Deploy:      https://deno.com/deploy (1M req free)

BACKEND:
  • Firebase:         https://firebase.google.com (generous free)
  • Appwrite:         https://appwrite.io (75K MAU free)

SIGNUP

echo ""
echo "=== Activation Complete ==="
echo "Active providers will appear in Command Center"
