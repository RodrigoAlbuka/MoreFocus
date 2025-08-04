#!/bin/bash

# MoreFocus Health Check Script
# Verifica se todos os serviços estão funcionando

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
    local service=$1
    local url=$2
    local expected_code=${3:-200}
    
    echo -n "Checking $service... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}OK${NC} ($response)"
        return 0
    else
        echo -e "${RED}FAIL${NC} ($response)"
        return 1
    fi
}

check_docker_service() {
    local service=$1
    echo -n "Checking Docker service $service... "
    
    if docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        return 1
    fi
}

echo "MoreFocus Health Check - $(date)"
echo "================================"

# Check Docker services
check_docker_service "morefocus-postgres"
check_docker_service "morefocus-redis"
check_docker_service "morefocus-n8n"
check_docker_service "morefocus-nginx"

echo ""

# Check HTTP endpoints
check_service "Nginx" "http://localhost/health"
check_service "n8n" "http://localhost:5678/healthz"

echo ""

# Check database connection
echo -n "Checking database connection... "
if docker exec morefocus-postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# Check Redis connection
echo -n "Checking Redis connection... "
if docker exec morefocus-redis redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

echo ""
echo "Health check completed."
