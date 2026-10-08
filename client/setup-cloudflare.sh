#!/bin/bash
# Setup Cloudflare URLs for OmniCaller Client

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OmniCaller Client - Cloudflare Setup                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env exists
if [ -f .env ]; then
    echo -e "${YELLOW}⚠ .env already exists. Backup created: .env.backup${NC}"
    cp .env .env.backup
else
    echo -e "${GREEN}✓ Creating .env from template${NC}"
    cp .env.example .env
fi

echo ""
echo -e "${YELLOW}Please enter your Cloudflare domain configuration:${NC}"
echo ""

# Get domain from user
read -p "Enter your domain (e.g., example.com): " domain

if [ -z "$domain" ]; then
    echo -e "${RED}❌ Domain cannot be empty!${NC}"
    exit 1
fi

# Update .env file
echo -e "${GREEN}Updating .env with Cloudflare URLs...${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|API_BASE_URL=.*|API_BASE_URL=https://api.${domain}|" .env
    sed -i '' "s|LIVEKIT_URL=.*|LIVEKIT_URL=wss://livekit.${domain}|" .env
    sed -i '' "s|ENV_MODE=.*|ENV_MODE=production|" .env
else
    # Linux
    sed -i "s|API_BASE_URL=.*|API_BASE_URL=https://api.${domain}|" .env
    sed -i "s|LIVEKIT_URL=.*|LIVEKIT_URL=wss://livekit.${domain}|" .env
    sed -i "s|ENV_MODE=.*|ENV_MODE=production|" .env
fi

echo ""
echo -e "${GREEN}✓ Configuration updated!${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "  API URL:      https://api.${domain}"
echo -e "  LiveKit URL:  wss://livekit.${domain}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Ask to test connection
read -p "Do you want to test the API connection? (y/n): " test_api

if [[ "$test_api" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Testing API connection...${NC}"
    
    if command -v curl &> /dev/null; then
        if curl -f -s "https://api.${domain}/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API is reachable!${NC}"
        else
            echo -e "${RED}❌ API is not reachable. Please check:${NC}"
            echo "  1. Cloudflare Tunnel is running"
            echo "  2. Domain DNS is configured correctly"
            echo "  3. Server is running"
        fi
    else
        echo -e "${YELLOW}⚠ curl not found, skipping test${NC}"
    fi
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup Complete! 🎉${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Run the app with Cloudflare URLs:"
echo -e "   ${BLUE}flutter run --dart-define-from-file=.env${NC}"
echo ""
echo "2. Or build release:"
echo -e "   ${BLUE}flutter build apk --release --dart-define-from-file=.env${NC}"
echo ""
echo "3. Check configuration in code:"
echo "   Add ApiConfig.printConfig() in main.dart"
echo ""
echo -e "For more details, see: ${BLUE}README_API_CONFIG.md${NC}"
echo ""
