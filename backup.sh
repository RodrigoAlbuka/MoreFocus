#!/bin/bash

# MoreFocus Backup Script
# Faz backup do banco de dados e configurações

BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting backup - $DATE"

# Backup do banco de dados
echo "Backing up database..."
docker exec morefocus-postgres pg_dump -U postgres morefocus | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"

# Backup das configurações n8n
echo "Backing up n8n data..."
docker exec morefocus-n8n tar czf - /home/node/.n8n > "$BACKUP_DIR/n8n_backup_$DATE.tar.gz"

# Backup dos arquivos de configuração
echo "Backing up configuration files..."
tar czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" docker-compose.yml nginx.conf .env

# Limpar backups antigos (manter apenas 7 dias)
find "$BACKUP_DIR" -name "*backup_*.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
ls -la "$BACKUP_DIR"
