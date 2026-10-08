#!/bin/bash
# Health Check Script for OmniCaller Services

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OmniCaller Health Check             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

check_service() {
    local service=$1
    local container=$2
    local test_cmd=$3
    
    echo -n "Checking $service... "
    
    if docker ps | grep -q "$container"; then
        if docker exec "$container" sh -c "$test_cmd" &> /dev/null; then
            echo -e "${GREEN}✓ Healthy${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Running but unhealthy${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Not running${NC}"
        return 2
    fi
}

check_port() {
    local service=$1
    local port=$2
    
    echo -n "Checking $service port $port... "
    
    if nc -z localhost "$port" 2>/dev/null; then
        echo -e "${GREEN}✓ Open${NC}"
        return 0
    else
        echo -e "${RED}✗ Closed${NC}"
        return 1
    fi
}

# Check containers
echo -e "${YELLOW}=== Container Status ===${NC}"
check_service "PostgreSQL" "omni-caller-postgres" "pg_isready -U postgres"
check_service "Redis" "omni-caller-redis" "redis-cli ping"
check_service "LiveKit" "omni-caller-livekit" "wget --spider -q http://localhost:7880"
check_service "Server" "omni-caller-server" "pidof omnicaller_server"
check_service "Cloudflared" "omni-caller-cloudflared" "pidof cloudflared"

echo ""
echo -e "${YELLOW}=== Port Accessibility ===${NC}"
check_port "Server" 3000
check_port "PostgreSQL" 5432
check_port "Redis" 6379
check_port "LiveKit" 7880

echo ""
echo -e "${YELLOW}=== Resource Usage ===${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep omni-caller

echo ""
echo -e "${YELLOW}=== Disk Usage ===${NC}"
docker system df | grep -E "(TYPE|Images|Containers|Local Volumes)"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo "For detailed logs, run: make logs"
echo "For specific service: make logs-server"
