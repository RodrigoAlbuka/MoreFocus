#!/bin/bash

# MoreFocus Resource Monitor
# Monitora uso de CPU, memória e disco

echo "MoreFocus Resource Monitor - $(date)"
echo "===================================="

# CPU Usage
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 $3}' | sed 's/%us,/% user,/' | sed 's/%sy/% system/'

# Memory Usage
echo ""
echo "Memory Usage:"
free -h | grep -E "^Mem|^Swap"

# Disk Usage
echo ""
echo "Disk Usage:"
df -h / | tail -1

# Docker Stats
echo ""
echo "Docker Container Stats:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Database Size
echo ""
echo "Database Size:"
docker exec morefocus-postgres psql -U postgres -d morefocus -c "
SELECT 
    pg_size_pretty(pg_database_size('morefocus')) as database_size,
    (SELECT count(*) FROM customers) as customers_count,
    (SELECT count(*) FROM workflows) as workflows_count,
    (SELECT count(*) FROM executions) as executions_count;
"

echo ""
echo "Free Tier Limits Check:"
echo "======================="

# Check if we're approaching free tier limits
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
if [ "$TOTAL_MEM" -gt 1000 ]; then
    echo "⚠️  Memory: ${TOTAL_MEM}MB (Free tier: 1GB)"
else
    echo "✅ Memory: ${TOTAL_MEM}MB (within free tier)"
fi

DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  Disk usage: ${DISK_USAGE}% (consider cleanup)"
else
    echo "✅ Disk usage: ${DISK_USAGE}%"
fi
