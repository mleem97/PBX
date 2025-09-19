# Deployment Script for FreePBX Container
#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
ENV_FILE="${ENV_FILE:-.env}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo -e "${GREEN}🚀 FreePBX Deployment Script${NC}"
echo "=================================="

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  No .env file found. Creating from template...${NC}"
    cp .env.example "$ENV_FILE"
    echo -e "${YELLOW}📝 Please edit $ENV_FILE with your configuration before running again.${NC}"
    exit 1
fi

# Source environment variables
source "$ENV_FILE"

# Validate required environment variables
required_vars=("IMAGE_REGISTRY" "IMAGE_REPO")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Required environment variable $var is not set${NC}"
        exit 1
    fi
done

echo -e "${GREEN}📥 Pulling latest image...${NC}"
docker compose -f "$COMPOSE_FILE" pull

echo -e "${GREEN}🛑 Stopping existing containers...${NC}"
docker compose -f "$COMPOSE_FILE" down

echo -e "${GREEN}🔧 Starting FreePBX services...${NC}"
docker compose -f "$COMPOSE_FILE" up -d

echo -e "${GREEN}⏳ Waiting for FreePBX to be ready...${NC}"
timeout 300 bash -c "
    while ! curl -f http://localhost:${HTTP_PORT:-8080} >/dev/null 2>&1; do
        echo -n '.'
        sleep 5
    done
" || {
    echo -e "${RED}❌ FreePBX failed to start within 5 minutes${NC}"
    echo -e "${YELLOW}📋 Checking logs...${NC}"
    docker compose -f "$COMPOSE_FILE" logs --tail=50
    exit 1
}

echo -e "${GREEN}✅ FreePBX deployment successful!${NC}"
echo ""
echo "🌐 Web Interface: http://localhost:${HTTP_PORT:-8080}"
echo "🔒 HTTPS Interface: https://localhost:${HTTPS_PORT:-8443}"
echo ""
echo "📊 Useful commands:"
echo "  View logs:        docker compose -f $COMPOSE_FILE logs -f"
echo "  Check status:     docker compose -f $COMPOSE_FILE ps"
echo "  Stop services:    docker compose -f $COMPOSE_FILE down"
echo "  Update:           $0"
echo ""
echo -e "${GREEN}🎉 Happy VoIP-ing!${NC}"