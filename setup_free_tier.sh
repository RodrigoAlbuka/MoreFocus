#!/bin/bash

# MoreFocus - Setup Automatizado para AWS Free Tier
# Este script configura a infraestrutura básica da MoreFocus usando apenas recursos gratuitos

set -e

echo "🚀 MoreFocus - Setup AWS Free Tier"
echo "=================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Verificar se está rodando no EC2
check_ec2() {
    log "Verificando se está rodando no EC2..."
    if curl -s --max-time 3 http://169.254.169.254/latest/meta-data/instance-id > /dev/null 2>&1; then
        INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
        log "Executando no EC2 - Instance ID: $INSTANCE_ID"
        log "IP Público: $PUBLIC_IP"
    else
        warn "Não está rodando no EC2. Algumas funcionalidades podem não funcionar."
    fi
}

# Atualizar sistema
update_system() {
    log "Atualizando sistema Ubuntu..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install -y curl wget git unzip software-properties-common
}

# Instalar Docker
install_docker() {
    log "Instalando Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
        log "Docker instalado com sucesso"
    else
        log "Docker já está instalado"
    fi
}

# Instalar Docker Compose
install_docker_compose() {
    log "Instalando Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log "Docker Compose instalado com sucesso"
    else
        log "Docker Compose já está instalado"
    fi
}

# Instalar AWS CLI
install_aws_cli() {
    log "Instalando AWS CLI..."
    if ! command -v aws &> /dev/null; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        log "AWS CLI instalado com sucesso"
    else
        log "AWS CLI já está instalado"
    fi
}

# Configurar variáveis de ambiente
setup_environment() {
    log "Configurando variáveis de ambiente..."
    
    # Criar arquivo .env se não existir
    if [ ! -f .env ]; then
        cat > .env << EOF
# MoreFocus Environment Variables
NODE_ENV=production
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=ChangeThisPassword123!
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://${PUBLIC_IP:-localhost}:5678/
GENERIC_TIMEZONE=America/Sao_Paulo

# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=localhost
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=morefocus
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=postgres123

# Email Configuration (Mailgun)
MAILGUN_API_KEY=your-mailgun-api-key
MAILGUN_DOMAIN=your-domain.com

# HubSpot Integration
HUBSPOT_ACCESS_TOKEN=your-hubspot-token

# Google Analytics
GA_MEASUREMENT_ID=G-XXXXXXXXXX
GA_API_SECRET=your-ga-secret
EOF
        log "Arquivo .env criado. IMPORTANTE: Edite as credenciais!"
        warn "Edite o arquivo .env com suas credenciais reais antes de continuar"
    fi
}

# Criar docker-compose.yml otimizado para free tier
create_docker_compose() {
    log "Criando docker-compose.yml otimizado..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:14-alpine
    container_name: morefocus-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: morefocus
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
      POSTGRES_INITDB_ARGS: "--encoding=UTF-8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    deploy:
      resources:
        limits:
          memory: 256M
        reservations:
          memory: 128M
    command: >
      postgres
      -c shared_buffers=64MB
      -c effective_cache_size=256MB
      -c maintenance_work_mem=32MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100
      -c random_page_cost=1.1
      -c effective_io_concurrency=200

  redis:
    image: redis:7-alpine
    container_name: morefocus-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          memory: 64M
        reservations:
          memory: 32M
    command: redis-server --maxmemory 48mb --maxmemory-policy allkeys-lru

  n8n:
    image: n8nio/n8n:latest
    container_name: morefocus-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=morefocus
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=postgres123
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=ChangeThisPassword123!
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:5678/
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_LOG_LEVEL=warn
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_VERSION_NOTIFICATIONS_ENABLED=false
      - N8N_TEMPLATES_ENABLED=false
      - N8N_ONBOARDING_FLOW_DISABLED=true
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
      - redis
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M

  nginx:
    image: nginx:alpine
    container_name: morefocus-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - n8n
    deploy:
      resources:
        limits:
          memory: 32M
        reservations:
          memory: 16M

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  n8n_data:
    driver: local
EOF

    log "docker-compose.yml criado com otimizações para free tier"
}

# Criar script de inicialização do banco
create_init_sql() {
    log "Criando script de inicialização do banco..."
    
    cat > init.sql << 'EOF'
-- MoreFocus Database Schema - Free Tier Optimized
-- Criado automaticamente pelo setup script

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de clientes
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    contact_name VARCHAR(255),
    phone VARCHAR(50),
    market CHAR(2) NOT NULL CHECK (market IN ('US', 'EU', 'BR', 'AR')),
    tier VARCHAR(20) NOT NULL DEFAULT 'starter' CHECK (tier IN ('starter', 'professional', 'enterprise')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices otimizados
CREATE INDEX IF NOT EXISTS idx_customers_market ON customers(market);
CREATE INDEX IF NOT EXISTS idx_customers_tier ON customers(tier);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(contact_email);

-- Tabela de workflows
CREATE TABLE IF NOT EXISTS workflows (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workflow_id VARCHAR(255), -- ID do workflow no n8n
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
    config JSONB, -- Configuração em JSON para economizar espaço
    last_execution TIMESTAMP,
    execution_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workflows_customer ON workflows(customer_id);
CREATE INDEX IF NOT EXISTS idx_workflows_status ON workflows(status);
CREATE INDEX IF NOT EXISTS idx_workflows_n8n_id ON workflows(workflow_id);

-- Tabela de execuções (com retenção automática)
CREATE TABLE IF NOT EXISTS executions (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER REFERENCES workflows(id) ON DELETE CASCADE,
    execution_id VARCHAR(255), -- ID da execução no n8n
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'error', 'waiting', 'running')),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    duration_ms INTEGER,
    error_message TEXT,
    data_size INTEGER DEFAULT 0 -- Tamanho dos dados processados
);

CREATE INDEX IF NOT EXISTS idx_executions_workflow ON executions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_executions_status ON executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_date ON executions(start_time);

-- Tabela de métricas agregadas (para economizar espaço)
CREATE TABLE IF NOT EXISTS metrics_daily (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    executions_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    total_duration_ms BIGINT DEFAULT 0,
    data_processed INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_metrics_daily_unique ON metrics_daily(date, customer_id);

-- Tabela de configurações do sistema
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir configurações iniciais
INSERT INTO system_config (key, value, description) VALUES
('retention_days', '30', 'Dias para manter execuções detalhadas'),
('max_executions_per_day', '1000', 'Máximo de execuções por dia por cliente'),
('backup_enabled', 'true', 'Se backup automático está habilitado'),
('monitoring_enabled', 'true', 'Se monitoramento está habilitado')
ON CONFLICT (key) DO NOTHING;

-- Função para limpeza automática de dados antigos
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
DECLARE
    retention_days INTEGER;
BEGIN
    -- Buscar configuração de retenção
    SELECT (value::text)::integer INTO retention_days 
    FROM system_config WHERE key = 'retention_days';
    
    IF retention_days IS NULL THEN
        retention_days := 30;
    END IF;
    
    -- Limpar execuções antigas
    DELETE FROM executions 
    WHERE start_time < NOW() - INTERVAL '1 day' * retention_days;
    
    -- Limpar métricas antigas (manter 90 dias)
    DELETE FROM metrics_daily 
    WHERE date < NOW() - INTERVAL '90 days';
    
    -- Log da limpeza
    RAISE NOTICE 'Cleanup completed. Retention: % days', retention_days;
END;
$$ LANGUAGE plpgsql;

-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_customers_updated_at 
    BEFORE UPDATE ON customers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflows_updated_at 
    BEFORE UPDATE ON workflows 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Função para agregar métricas diárias
CREATE OR REPLACE FUNCTION aggregate_daily_metrics()
RETURNS void AS $$
BEGIN
    INSERT INTO metrics_daily (
        date, customer_id, executions_count, success_count, 
        error_count, total_duration_ms, data_processed
    )
    SELECT 
        DATE(e.start_time) as date,
        w.customer_id,
        COUNT(*) as executions_count,
        COUNT(*) FILTER (WHERE e.status = 'success') as success_count,
        COUNT(*) FILTER (WHERE e.status = 'error') as error_count,
        COALESCE(SUM(e.duration_ms), 0) as total_duration_ms,
        COALESCE(SUM(e.data_size), 0) as data_processed
    FROM executions e
    JOIN workflows w ON e.workflow_id = w.id
    WHERE DATE(e.start_time) = CURRENT_DATE - INTERVAL '1 day'
    GROUP BY DATE(e.start_time), w.customer_id
    ON CONFLICT (date, customer_id) DO UPDATE SET
        executions_count = EXCLUDED.executions_count,
        success_count = EXCLUDED.success_count,
        error_count = EXCLUDED.error_count,
        total_duration_ms = EXCLUDED.total_duration_ms,
        data_processed = EXCLUDED.data_processed;
END;
$$ LANGUAGE plpgsql;

-- Inserir cliente de exemplo para testes
INSERT INTO customers (company_name, contact_email, contact_name, market, tier) VALUES
('MoreFocus Demo', 'demo@morefocus.com', 'Demo User', 'BR', 'starter')
ON CONFLICT (contact_email) DO NOTHING;

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'MoreFocus database initialized successfully!';
    RAISE NOTICE 'Free tier optimizations applied.';
    RAISE NOTICE 'Remember to run cleanup_old_data() periodically.';
END $$;
EOF

    log "Script de inicialização do banco criado"
}

# Criar configuração do Nginx
create_nginx_config() {
    log "Criando configuração do Nginx..."
    
    cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream n8n {
        server n8n:5678;
    }
    
    # Configurações de compressão para economizar bandwidth
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Rate limiting para proteger recursos
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    server {
        listen 80;
        server_name _;
        
        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;
        add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
        
        # Rate limiting
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        location /rest/login {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://n8n;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
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
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    log "Configuração do Nginx criada"
}

# Criar scripts de monitoramento
create_monitoring_scripts() {
    log "Criando scripts de monitoramento..."
    
    # Script de health check
    cat > health_check.sh << 'EOF'
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
EOF

    chmod +x health_check.sh

    # Script de backup
    cat > backup.sh << 'EOF'
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
EOF

    chmod +x backup.sh

    # Script de monitoramento de recursos
    cat > monitor_resources.sh << 'EOF'
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
EOF

    chmod +x monitor_resources.sh

    log "Scripts de monitoramento criados"
}

# Criar cron jobs para manutenção
setup_cron_jobs() {
    log "Configurando cron jobs para manutenção..."
    
    # Criar script de manutenção diária
    cat > daily_maintenance.sh << 'EOF'
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
EOF

    chmod +x daily_maintenance.sh

    # Adicionar ao crontab
    (crontab -l 2>/dev/null; echo "0 2 * * * /home/ubuntu/daily_maintenance.sh >> /var/log/morefocus_maintenance.log 2>&1") | crontab -
    (crontab -l 2>/dev/null; echo "*/15 * * * * /home/ubuntu/health_check.sh >> /var/log/morefocus_health.log 2>&1") | crontab -
    
    log "Cron jobs configurados: backup diário às 2h e health check a cada 15min"
}

# Função principal de setup
main() {
    log "Iniciando setup da MoreFocus - Free Tier"
    
    check_ec2
    update_system
    install_docker
    install_docker_compose
    install_aws_cli
    setup_environment
    create_docker_compose
    create_init_sql
    create_nginx_config
    create_monitoring_scripts
    setup_cron_jobs
    
    log "Setup básico concluído!"
    echo ""
    echo -e "${BLUE}Próximos passos:${NC}"
    echo "1. Edite o arquivo .env com suas credenciais"
    echo "2. Execute: docker-compose up -d"
    echo "3. Acesse n8n em: http://${PUBLIC_IP:-localhost}:5678"
    echo "4. Configure seus workflows"
    echo ""
    echo -e "${YELLOW}Scripts disponíveis:${NC}"
    echo "./health_check.sh - Verificar saúde do sistema"
    echo "./backup.sh - Fazer backup manual"
    echo "./monitor_resources.sh - Monitorar recursos"
    echo ""
    echo -e "${GREEN}Setup concluído com sucesso! 🚀${NC}"
}

# Executar função principal
main "$@"
EOF

chmod +x setup_free_tier.sh

