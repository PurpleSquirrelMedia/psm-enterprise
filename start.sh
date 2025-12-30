#!/bin/bash
# PSM Enterprise - Master Startup Script
# Launches all services for the Virtual Serverless Empire

set -e

ENTERPRISE_DIR="/Volumes/Virtual Server/projects/psm-enterprise"
PROCESSOR_DIR="/Volumes/Virtual Server/projects/psm-processor"

RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║     PURPLE SQUIRREL MEDIA - ENTERPRISE STARTUP                             ║"
echo "║     Virtual Serverless Empire                                              ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check if a port is in use
check_port() {
    lsof -i :$1 > /dev/null 2>&1
    return $?
}

# Start Unified API Gateway
echo -e "${CYAN}[1/3] Starting Unified API Gateway...${NC}"
if check_port 3002; then
    echo -e "${YELLOW}  Gateway already running on port 3002${NC}"
else
    cd "$ENTERPRISE_DIR/gateway"
    node unified-api.js &
    sleep 1
    if check_port 3002; then
        echo -e "${GREEN}  ✓ Gateway started on http://localhost:3002${NC}"
    else
        echo -e "${RED}  ✗ Gateway failed to start${NC}"
    fi
fi

# Start PSM Processor
echo -e "${CYAN}[2/3] Starting PSM Processor...${NC}"
if check_port 3001; then
    echo -e "${YELLOW}  Processor already running on port 3001${NC}"
else
    cd "$PROCESSOR_DIR"
    if [ -f "package.json" ]; then
        npm start &
        sleep 2
        if check_port 3001; then
            echo -e "${GREEN}  ✓ Processor started on http://localhost:3001${NC}"
        else
            echo -e "${RED}  ✗ Processor failed to start${NC}"
        fi
    else
        echo -e "${YELLOW}  Processor not configured${NC}"
    fi
fi

# Run Health Check
echo ""
echo -e "${CYAN}[3/3] Running Health Check...${NC}"
node "$ENTERPRISE_DIR/services/health-monitor.js"

# Summary
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}PSM Enterprise Started${NC}"
echo ""
echo "Local Services:"
echo "  - API Gateway:      http://localhost:3002"
echo "  - PSM Processor:    http://localhost:3001"
echo "  - Command Center:   file://$ENTERPRISE_DIR/dashboards/command-center.html"
echo ""
echo "Cloud Services:"
echo "  - Azure Website:    https://purplesquirrel.media"
echo "  - Vercel Edge:      https://vercel-dusky-pi.vercel.app/api/status"
echo "  - Oracle Jellyfin:  http://163.192.105.31:8096"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
