#!/bin/bash
# PSM Enterprise - Deploy to All Clouds
# Usage: ./deploy-all.sh [cloud]

set -e

ENTERPRISE_DIR="/Volumes/Virtual Server/projects/psm-enterprise"
cd "$ENTERPRISE_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     PSM ENTERPRISE - GLOBAL CLOUD DEPLOYMENT               ║"
echo "║     Virtual Serverless Empire                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

deploy_cloudflare() {
    echo -e "${CYAN}[Cloudflare]${NC} Deploying Workers..."
    cd "$ENTERPRISE_DIR/workers/cloudflare"
    if wrangler deploy 2>/dev/null; then
        echo -e "${GREEN}✓ Cloudflare Workers deployed${NC}"
    else
        echo -e "${RED}✗ Cloudflare deployment failed (run 'wrangler login' first)${NC}"
    fi
}

deploy_vercel() {
    echo -e "${CYAN}[Vercel]${NC} Deploying Edge Functions..."
    cd "$ENTERPRISE_DIR/functions/vercel"
    if vercel --prod -y 2>/dev/null; then
        echo -e "${GREEN}✓ Vercel Functions deployed${NC}"
    else
        echo -e "${RED}✗ Vercel deployment failed (run 'vercel login' first)${NC}"
    fi
}

deploy_aws() {
    echo -e "${CYAN}[AWS]${NC} Deploying Lambda Functions..."
    cd "$ENTERPRISE_DIR/functions/aws"
    echo "AWS deployment requires SAM CLI. Run:"
    echo "  sam build && sam deploy --guided"
}

deploy_gcp() {
    echo -e "${CYAN}[GCP]${NC} Deploying Cloud Functions..."
    cd "$ENTERPRISE_DIR/functions/gcp"
    echo "GCP deployment. Run:"
    echo "  gcloud functions deploy psm-status --runtime nodejs18 --trigger-http --allow-unauthenticated"
}

check_status() {
    echo ""
    echo -e "${PURPLE}=== Deployment Status ===${NC}"
    echo ""
    
    # Check Cloudflare
    echo -n "Cloudflare Workers: "
    if curl -s "https://psm-api.purplesquirrel.workers.dev/api/status" 2>/dev/null | grep -q "operational"; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
    
    # Check Vercel
    echo -n "Vercel Functions: "
    if curl -s "https://psm-functions.vercel.app/api/status" 2>/dev/null | grep -q "operational"; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
    
    # Check Azure
    echo -n "Azure Static Web: "
    if curl -s -I "https://purplesquirrel.media" 2>/dev/null | grep -q "200"; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}OFFLINE${NC}"
    fi
}

case "${1:-all}" in
    cloudflare) deploy_cloudflare ;;
    vercel) deploy_vercel ;;
    aws) deploy_aws ;;
    gcp) deploy_gcp ;;
    status) check_status ;;
    all)
        deploy_cloudflare
        deploy_vercel
        deploy_aws
        deploy_gcp
        check_status
        ;;
    *)
        echo "Usage: $0 [cloudflare|vercel|aws|gcp|status|all]"
        exit 1
        ;;
esac

echo ""
echo -e "${PURPLE}Deployment complete!${NC}"
