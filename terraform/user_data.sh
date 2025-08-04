#!/bin/bash

# MoreFocus - EC2 User Data Script
# Configuração automatizada com Supabase PostgreSQL

set -e

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== MoreFocus EC2 Setup Started at $(date) ==="

# Atualizar sistema
apt-get update -y
apt-get install -y curl wget git docker.io docker-compose

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Obter IP público via metadata
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Criar diretório
mkdir -p /opt/${PROJECT_NAME}
cd /opt/${PROJECT_NAME}

# Criar docker-compose.yml
cat > docker-compose.yml << COMPOSE_EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: morefocus-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
      - "80:5678"
    environment:
      - NODE_ENV=production
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - WEBHOOK_URL=http://0.0.0.0:5678/
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=${SUPABASE_HOST}
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${DB_NAME}
      - DB_POSTGRESDB_USER=${DB_USER}
      - DB_POSTGRESDB_PASSWORD=${SUPABASE_PASSWORD}
      - DB_POSTGRESDB_SSL=true
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
    driver: local
COMPOSE_EOF

# Iniciar serviços
chown -R ubuntu:ubuntu /opt/${PROJECT_NAME}
docker-compose up -d

# Aguardar n8n
sleep 30

# Verificar se funcionou
if curl -f http://localhost:5678/ > /dev/null 2>&1; then
    echo "✅ n8n running successfully!"
else
    echo "❌ n8n failed to start"
fi

# Status
cat > status.json << STATUS_EOF
{
    "installation_date": "$(date -Iseconds)",
    "n8n_url": "http://0.0.0.0:5678/",
    "credentials": {
        "username": "${N8N_USER}",
        "password": "${N8N_PASSWORD}"
    },
    "database": "Supabase PostgreSQL"
}
STATUS_EOF

# echo "=== Setup completed! Access: http://0.0.0.0:5678/ ==="
echo "Username: ${N8N_USER}"
echo "Password: ${N8N_PASSWORD}"
