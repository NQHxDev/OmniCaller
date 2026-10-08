#!/bin/bash
# OmniCaller Server Setup Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   OmniCaller Server Setup Script       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check Docker
echo -e "${YELLOW}[1/6] Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed!${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}✓ Docker installed: $(docker --version)${NC}"

# Check Docker Compose
echo -e "${YELLOW}[2/6] Checking Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed!${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose installed${NC}"

# Setup .env
echo -e "${YELLOW}[3/6] Setting up environment file...${NC}"
if [ -f .env ]; then
    echo -e "${YELLOW}.env already exists. Preserving existing secrets and configuration.${NC}"
else
    echo -e "${GREEN}✓ Creating .env from .env.example${NC}"
    cp .env.example .env

    # Generate secure secrets
    echo -e "${YELLOW}[4/6] Generating secure secrets...${NC}"
    generate_secret() {
        openssl rand -base64 48 | tr -d "=+/" | cut -c1-64
    }

    JWT_ACCESS=$(generate_secret)
    JWT_REFRESH=$(generate_secret)
    POSTGRES_PASS=$(generate_secret | cut -c1-32)

    # Update .env with generated secrets
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|JWT_ACCESS_SECRET=.*|JWT_ACCESS_SECRET=${JWT_ACCESS}|" .env
        sed -i '' "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=${JWT_REFRESH}|" .env
        sed -i '' "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASS}|" .env
    else
        # Linux
        sed -i "s|JWT_ACCESS_SECRET=.*|JWT_ACCESS_SECRET=${JWT_ACCESS}|" .env
        sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=${JWT_REFRESH}|" .env
        sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${POSTGRES_PASS}|" .env
    fi

    echo -e "${GREEN}✓ Secure secrets generated${NC}"
fi

# Cloudflare setup
echo -e "${YELLOW}[5/6] Cloudflare Tunnel configuration...${NC}"
read -p "Do you have a Cloudflare Tunnel token? (y/n): " has_token

if [[ "$has_token" =~ ^[Yy]$ ]]; then
    read -p "Enter your Cloudflare Tunnel token: " tunnel_token
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|CLOUDFLARE_TUNNEL_TOKEN=.*|CLOUDFLARE_TUNNEL_TOKEN=${tunnel_token}|" .env
    else
        sed -i "s|CLOUDFLARE_TUNNEL_TOKEN=.*|CLOUDFLARE_TUNNEL_TOKEN=${tunnel_token}|" .env
    fi
    echo -e "${GREEN}✓ Cloudflare token configured${NC}"
else
    echo -e "${YELLOW}⚠ Skipping Cloudflare configuration${NC}"
    echo -e "Please see CLOUDFLARE_SETUP.md for instructions"
fi

# Build and start
echo -e "${YELLOW}[6/6] Building and starting services...${NC}"
read -p "Do you want to start the services now? (y/n): " start_now

if [[ "$start_now" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Building Docker images...${NC}"
    docker-compose build

    echo -e "${GREEN}Starting services...${NC}"
    docker-compose up -d

    echo ""
    echo -e "${GREEN}✓ Services started successfully!${NC}"
    echo ""
    echo "Waiting for services to be healthy..."
    sleep 10

    docker-compose ps

    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}Setup Complete! 🎉${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "Services running:"
    echo "  • Server: http://localhost:3000"
    echo "  • PostgreSQL: localhost:5432"
    echo "  • Redis: localhost:6379"
    echo "  • LiveKit: http://localhost:7880"
    echo ""
    echo "Useful commands:"
    echo "  • View logs: make logs"
    echo "  • Check health: make health"
    echo "  • Stop services: make down"
    echo ""
    echo "Next steps:"
    echo "  1. Configure Cloudflare Tunnel (see CLOUDFLARE_SETUP.md)"
    echo "  2. Update your domain in Cloudflare Dashboard"
    echo "  3. Test your API endpoints"
    echo ""
else
    echo -e "${GREEN}✓ Setup complete!${NC}"
    echo ""
    echo "To start services later, run:"
    echo "  make up"
fi

echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  • Never commit .env file to git"
echo "  • Keep your secrets secure"
echo "  • See DOCKER_README.md for full documentation"
