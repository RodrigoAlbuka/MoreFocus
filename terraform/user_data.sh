#!/bin/bash

# MoreFocus - EC2 User Data Script
# Configuração automatizada com Supabase PostgreSQL
# Variáveis padronizadas em UPPER_CASE

set -e

# Variáveis do template (UPPER_CASE)
N8N_USER="${N8N_USER}"
N8N_PASSWORD="${N8N_PASSWORD}"
SUPABASE_HOST="${SUPABASE_HOST}"
SUPABASE_PASSWORD="${SUPABASE_PASSWORD}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
PROJECT_NAME="${PROJECT_NAME}"

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== MoreFocus EC2 Setup Started at $(date) ==="
echo "Project: $PROJECT_NAME"
echo "n8n User: $N8N_USER"
echo "Database: Supabase PostgreSQL"

# Atualizar sistema
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Instalar dependências básicas
echo "Installing basic dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    nano \
    jq \
    awscli

# Instalar Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar Docker
systemctl start docker
systemctl enable docker

# Adicionar usuário ubuntu ao grupo docker
usermod -aG docker ubuntu

# Instalar Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Criar diretório do projeto
echo "Setting up project directory..."
mkdir -p /opt/$PROJECT_NAME
cd /opt/$PROJECT_NAME

# Obter IP público da instância
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Criar arquivo .env
echo "Creating environment configuration..."
cat > .env << EOF
# MoreFocus Environment Variables
NODE_ENV=production
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=$N8N_USER
N8N_BASIC_AUTH_PASSWORD=$N8N_PASSWORD
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://$PUBLIC_IP:5678/
GENERIC_TIMEZONE=America/Sao_Paulo

# Supabase PostgreSQL Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=$SUPABASE_HOST
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=$DB_NAME
DB_POSTGRESDB_USER=$DB_USER
DB_POSTGRESDB_PASSWORD=$SUPABASE_PASSWORD
DB_POSTGRESDB_SSL=true

# n8n Configuration
N8N_LOG_LEVEL=info
N8N_DIAGNOSTICS_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
N8N_TEMPLATES_ENABLED=true
N8N_ONBOARDING_FLOW_DISABLED=false
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168
N8N_RUNNERS_ENABLED=true
N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false
EOF

# Criar docker-compose.yml
echo "Creating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: morefocus-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
      - "80:5678"
    env_file:
      - .env
    volumes:
      - n8n_data:/home/node/.n8n
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  n8n_data:
    driver: local
EOF

# Criar scripts de manutenção
echo "Creating maintenance scripts..."
mkdir -p scripts

cat > scripts/backup.sh << 'BACKUP_EOF'
#!/bin/bash
# Backup script for MoreFocus

BACKUP_DIR="/opt/morefocus/backups"
DATE=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="morefocus-backups"

mkdir -p $BACKUP_DIR

# Backup n8n data
echo "Backing up n8n data..."
docker exec morefocus-n8n tar czf /tmp/n8n_backup_$DATE.tar.gz -C /home/node/.n8n .
docker cp morefocus-n8n:/tmp/n8n_backup_$DATE.tar.gz $BACKUP_DIR/

# Upload to S3 (if configured)
if command -v aws &> /dev/null; then
    echo "Uploading backup to S3..."
    aws s3 cp $BACKUP_DIR/n8n_backup_$DATE.tar.gz s3://$S3_BUCKET/backups/ || echo "S3 upload failed"
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "n8n_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: n8n_backup_$DATE.tar.gz"
BACKUP_EOF

cat > scripts/health_check.sh << 'HEALTH_EOF'
#!/bin/bash
# Health check script for MoreFocus

echo "=== MoreFocus Health Check ==="
echo "Date: $(date)"

# Check Docker
if systemctl is-active --quiet docker; then
    echo "✅ Docker: Running"
else
    echo "❌ Docker: Not running"
fi

# Check n8n container
if docker ps | grep -q morefocus-n8n; then
    echo "✅ n8n Container: Running"
else
    echo "❌ n8n Container: Not running"
fi

# Check n8n health
if curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
    echo "✅ n8n Health: OK"
else
    echo "❌ n8n Health: Failed"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 80 ]; then
    echo "✅ Disk Usage: ${DISK_USAGE}%"
else
    echo "⚠️ Disk Usage: ${DISK_USAGE}% (High)"
fi

# Check memory
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -lt 80 ]; then
    echo "✅ Memory Usage: ${MEMORY_USAGE}%"
else
    echo "⚠️ Memory Usage: ${MEMORY_USAGE}% (High)"
fi

echo "=== End Health Check ==="
HEALTH_EOF

chmod +x scripts/*.sh

# Configurar cron jobs
echo "Setting up cron jobs..."
cat > /tmp/morefocus-cron << 'CRON_EOF'
# MoreFocus maintenance cron jobs
0 2 * * * /opt/morefocus/scripts/backup.sh >> /var/log/morefocus-backup.log 2>&1
*/15 * * * * /opt/morefocus/scripts/health_check.sh >> /var/log/morefocus-health.log 2>&1
CRON_EOF

crontab /tmp/morefocus-cron

# Configurar logrotate
echo "Configuring log rotation..."
cat > /etc/logrotate.d/morefocus << 'LOGROTATE_EOF'
/var/log/morefocus-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
LOGROTATE_EOF

# Configurar firewall básico
echo "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 5678

# Definir propriedade dos arquivos
chown -R ubuntu:ubuntu /opt/$PROJECT_NAME

# Iniciar serviços
echo "Starting MoreFocus services..."
cd /opt/$PROJECT_NAME
docker-compose up -d

# Aguardar n8n inicializar
echo "Waiting for n8n to start..."
sleep 30

# Verificar se n8n está rodando
RETRY_COUNT=0
MAX_RETRIES=10

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
        echo "✅ n8n is running successfully with Supabase!"
        break
    else
        echo "⏳ Waiting for n8n... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
        sleep 10
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ n8n failed to start after $MAX_RETRIES attempts"
    echo "Check logs: docker logs morefocus-n8n"
fi

# Criar arquivo de status
cat > /opt/$PROJECT_NAME/status.json << EOF
{
    "installation_date": "$(date -Iseconds)",
    "version": "1.0.0",
    "project_name": "$PROJECT_NAME",
    "services": {
        "n8n": "$(docker inspect morefocus-n8n --format='{{.State.Status}}' 2>/dev/null || echo 'not found')",
        "database": "Supabase PostgreSQL"
    },
    "endpoints": {
        "n8n_interface": "http://$PUBLIC_IP:5678/",
        "webhooks": {
            "prospeccao": "http://$PUBLIC_IP:5678/webhook/prospeccao",
            "nutricao": "http://$PUBLIC_IP:5678/webhook/nutricao",
            "vendas": "http://$PUBLIC_IP:5678/webhook/vendas"
        }
    },
    "credentials": {
        "username": "$N8N_USER",
        "password": "$N8N_PASSWORD"
    },
    "database": {
        "type": "PostgreSQL",
        "provider": "Supabase",
        "host": "$SUPABASE_HOST",
        "ssl": true
    }
}
EOF

echo "=== MoreFocus EC2 Setup Completed at $(date) ==="
echo ""
echo "🎉 MoreFocus instalado com sucesso!"
echo "=================================="
echo ""
echo "📋 Informações de acesso:"
echo "  🌐 n8n Interface: http://$PUBLIC_IP:5678/"
echo "  👤 Usuário: $N8N_USER"
echo "  🔑 Senha: $N8N_PASSWORD"
echo ""
echo "🔗 Webhooks:"
echo "  📊 APQ (Prospecção): http://$PUBLIC_IP:5678/webhook/prospeccao"
echo "  📧 ANE (Nutrição): http://$PUBLIC_IP:5678/webhook/nutricao"
echo "  💰 AVC (Vendas): http://$PUBLIC_IP:5678/webhook/vendas"
echo ""
echo "🗄️ Database: Supabase PostgreSQL"
echo "📁 Status file: /opt/$PROJECT_NAME/status.json"
echo "📋 Logs: /var/log/user-data.log"
echo ""
echo "🚀 Próximos passos:"
echo "1. Importar workflows JSON no n8n"
echo "2. Ativar workflows na interface"
echo "3. Configurar integrações externas"
echo "4. Testar webhooks"

