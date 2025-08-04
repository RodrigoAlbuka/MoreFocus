#!/bin/bash

# MoreFocus - EC2 User Data Script
# Este script configura automaticamente a instância EC2

set -e

# Variáveis do template
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
N8N_USER="${n8n_user}"
N8N_PASSWORD="${n8n_password}"
USE_RDS="${use_rds}"

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== MoreFocus EC2 Setup Started at $(date) ==="

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
mkdir -p /opt/morefocus
cd /opt/morefocus

# Criar arquivo .env
echo "Creating environment configuration..."
cat > .env << EOF
# MoreFocus Environment Variables
NODE_ENV=production
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=${N8N_USER}
N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/
GENERIC_TIMEZONE=America/Sao_Paulo

# Database Configuration
EOF

if [ "${USE_RDS}" = "true" ]; then
    echo "Configuring PostgreSQL database..."
    cat >> .env << EOF
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=${DB_HOST}
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=${DB_NAME}
DB_POSTGRESDB_USER=${DB_USER}
DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
EOF
else
    echo "Configuring SQLite database..."
    cat >> .env << EOF
DB_TYPE=sqlite
DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
EOF
fi

cat >> .env << EOF

# Email Configuration (Mailgun)
MAILGUN_API_KEY=
MAILGUN_DOMAIN=

# HubSpot Integration
HUBSPOT_ACCESS_TOKEN=

# Google Analytics
GA_MEASUREMENT_ID=
GA_API_SECRET=

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
if [ "${USE_RDS}" = "true" ]; then
    # Configuração com RDS PostgreSQL
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: morefocus-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru

  n8n:
    image: n8nio/n8n:latest
    container_name: morefocus-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=${DB_POSTGRESDB_HOST}
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${DB_POSTGRESDB_DATABASE}
      - DB_POSTGRESDB_USER=${DB_POSTGRESDB_USER}
      - DB_POSTGRESDB_PASSWORD=${DB_POSTGRESDB_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_LOG_LEVEL=info
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_VERSION_NOTIFICATIONS_ENABLED=false
      - N8N_TEMPLATES_ENABLED=true
      - N8N_ONBOARDING_FLOW_DISABLED=false
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      - N8N_RUNNERS_ENABLED=true
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - redis

  nginx:
    image: nginx:alpine
    container_name: morefocus-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - n8n

volumes:
  redis_data:
    driver: local
  n8n_data:
    driver: local
EOF
else
    # Configuração com SQLite (Free Tier)
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
    environment:
      - DB_TYPE=sqlite
      - DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=${WEBHOOK_URL}
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_LOG_LEVEL=info
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_VERSION_NOTIFICATIONS_ENABLED=false
      - N8N_TEMPLATES_ENABLED=true
      - N8N_ONBOARDING_FLOW_DISABLED=false
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      - N8N_RUNNERS_ENABLED=true
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
    driver: local
EOF
fi

# Configurar Nginx (se usando RDS)
if [ "${USE_RDS}" = "true" ]; then
    echo "Configuring Nginx..."
    mkdir -p ssl
    
    cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream n8n {
        server n8n:5678;
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
EOF
fi

# Criar scripts de manutenção
echo "Creating maintenance scripts..."
mkdir -p scripts

cat > scripts/backup.sh << 'EOF'
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
    aws s3 cp $BACKUP_DIR/n8n_backup_$DATE.tar.gz s3://$S3_BUCKET/backups/
fi

# Cleanup old backups (keep last 7 days)
find $BACKUP_DIR -name "n8n_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: n8n_backup_$DATE.tar.gz"
EOF

cat > scripts/restore.sh << 'EOF'
#!/bin/bash
# Restore script for MoreFocus

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Stopping n8n..."
docker stop morefocus-n8n

echo "Restoring backup..."
docker cp $BACKUP_FILE morefocus-n8n:/tmp/restore.tar.gz
docker exec morefocus-n8n tar xzf /tmp/restore.tar.gz -C /home/node/.n8n

echo "Starting n8n..."
docker start morefocus-n8n

echo "Restore completed!"
EOF

cat > scripts/update.sh << 'EOF'
#!/bin/bash
# Update script for MoreFocus

echo "Updating MoreFocus..."

cd /opt/morefocus

# Backup before update
./scripts/backup.sh

# Pull latest images
docker-compose pull

# Restart services
docker-compose down
docker-compose up -d

echo "Update completed!"
EOF

chmod +x scripts/*.sh

# Configurar cron jobs
echo "Setting up cron jobs..."
cat > /tmp/morefocus-cron << 'EOF'
# MoreFocus maintenance cron jobs
0 2 * * * /opt/morefocus/scripts/backup.sh >> /var/log/morefocus-backup.log 2>&1
0 4 * * 0 /opt/morefocus/scripts/update.sh >> /var/log/morefocus-update.log 2>&1
EOF

crontab /tmp/morefocus-cron

# Configurar logrotate
echo "Configuring log rotation..."
cat > /etc/logrotate.d/morefocus << 'EOF'
/var/log/morefocus-*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Configurar firewall básico
echo "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 5678

# Instalar CloudWatch agent (se disponível)
if command -v aws &> /dev/null; then
    echo "Installing CloudWatch agent..."
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i amazon-cloudwatch-agent.deb || true
    
    # Configuração básica do CloudWatch
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/morefocus",
                        "log_stream_name": "user-data"
                    },
                    {
                        "file_path": "/var/log/morefocus-*.log",
                        "log_group_name": "/aws/ec2/morefocus",
                        "log_stream_name": "application"
                    }
                ]
            }
        }
    }
}
EOF
    
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
fi

# Definir propriedade dos arquivos
chown -R ubuntu:ubuntu /opt/morefocus

# Iniciar serviços
echo "Starting MoreFocus services..."
cd /opt/morefocus
docker-compose up -d

# Aguardar n8n inicializar
echo "Waiting for n8n to start..."
sleep 30

# Verificar se n8n está rodando
if curl -f http://localhost:5678/ > /dev/null 2>&1; then
    echo "✅ n8n is running successfully!"
else
    echo "❌ n8n failed to start. Check logs: docker logs morefocus-n8n"
fi

# Criar arquivo de status
cat > /opt/morefocus/status.json << EOF
{
    "installation_date": "$(date -Iseconds)",
    "version": "1.0.0",
    "services": {
        "n8n": "$(docker inspect morefocus-n8n --format='{{.State.Status}}')",
        "database": "${USE_RDS}"
    },
    "endpoints": {
        "n8n_interface": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/",
        "webhooks": {
            "prospeccao": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/webhook/prospeccao",
            "nutricao": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/webhook/nutricao",
            "vendas": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/webhook/vendas"
        }
    }
}
EOF

echo "=== MoreFocus EC2 Setup Completed at $(date) ==="
echo "Access n8n at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5678/"
echo "Username: ${N8N_USER}"
echo "Password: ${N8N_PASSWORD}"
echo ""
echo "Next steps:"
echo "1. Import workflows from the JSON files"
echo "2. Activate workflows in n8n interface"
echo "3. Configure external integrations (email, CRM)"
echo "4. Test webhooks"
echo ""
echo "Status file: /opt/morefocus/status.json"
echo "Logs: /var/log/user-data.log"

