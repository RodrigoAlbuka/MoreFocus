#!/bin/bash

# MoreFocus Daily Maintenance
# Executa limpeza e backup diário

echo "$(date): Starting daily maintenance"

# Limpeza do banco de dados
docker exec morefocus-postgres psql -U postgres -d morefocus -c "SELECT cleanup_old_data();"

# Agregação de métricas
docker exec morefocus-postgres psql -U postgres -d morefocus -c "SELECT aggregate_daily_metrics();"

# Backup
/home/ubuntu/backup.sh

# Limpeza de logs do Docker
docker system prune -f --volumes

echo "$(date): Daily maintenance completed"
