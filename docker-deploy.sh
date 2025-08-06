#!/bin/bash

# MoreFocus - Script de Deploy Docker
# Deploy simplificado em qualquer servidor com Docker

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Banner
echo "🐳 MoreFocus - Deploy Docker"
echo "============================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    log_error "Docker não encontrado!"
    echo ""
    echo "📥 Instale o Docker:"
    echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
    echo "  CentOS/RHEL: curl -fsSL https://get.docker.com | sh"
    echo "  Windows: https://docs.docker.com/desktop/windows/install/"
    echo "  macOS: https://docs.docker.com/desktop/mac/install/"
    exit 1
fi

# Verificar se Docker Compose está disponível
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose não encontrado!"
    echo ""
    echo "📥 Instale o Docker Compose:"
    echo "  curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
    echo "  chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

# Detectar comando do Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

log_success "Docker e Docker Compose encontrados!"

# Verificar se está no diretório correto
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.production.yml" ]; then
    log_error "Execute este script no diretório raiz do projeto MoreFocus"
    exit 1
fi

# Verificar arquivo .env
if [ ! -f ".env" ]; then
    log_warning "Arquivo .env não encontrado"
    
    read -p "Deseja criar um arquivo .env básico? (y/n): " create_env
    if [ "$create_env" = "y" ]; then
        log_info "Criando arquivo .env..."
        
        # Gerar senha aleatória
        RANDOM_PASSWORD=$(openssl rand -base64 12 2>/dev/null || date +%s | sha256sum | base64 | head -c 12)
        
        # Detectar IP público
        PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "localhost")
        
        cat > .env << EOF
# MoreFocus - Configuração Básica
N8N_USER=admin
N8N_PASSWORD=$RANDOM_PASSWORD
WEBHOOK_URL=http://$PUBLIC_IP:5678/
DB_TYPE=sqlite
LOG_LEVEL=info
EOF
        
        log_success "Arquivo .env criado!"
        log_warning "Senha gerada: $RANDOM_PASSWORD"
        log_info "Edite o arquivo .env se necessário: nano .env"
        
        read -p "Pressione Enter para continuar..."
    else
        log_error "Crie o arquivo .env baseado no exemplo"
        log_info "cp .env.example .env && nano .env"
        exit 1
    fi
fi

# Mostrar configuração
log_info "Configuração do deploy:"
source .env
echo "  - Usuário n8n: ${N8N_USER:-admin}"
echo "  - Webhook URL: ${WEBHOOK_URL:-http://localhost:5678/}"
echo "  - Banco de dados: ${DB_TYPE:-sqlite}"
echo "  - Log level: ${LOG_LEVEL:-info}"
echo ""

# Opções de deploy
echo "🚀 Opções de deploy:"
echo "  1. Deploy básico (apenas MoreFocus)"
echo "  2. Deploy com PostgreSQL local"
echo "  3. Deploy com Redis cache"
echo "  4. Deploy completo (PostgreSQL + Redis + SSL)"
echo ""

read -p "Escolha uma opção (1-4): " deploy_option

case $deploy_option in
    1)
        PROFILES=""
        log_info "Deploy básico selecionado"
        ;;
    2)
        PROFILES="--profile postgres"
        log_info "Deploy com PostgreSQL selecionado"
        ;;
    3)
        PROFILES="--profile redis"
        log_info "Deploy com Redis selecionado"
        ;;
    4)
        PROFILES="--profile postgres --profile redis --profile ssl"
        log_info "Deploy completo selecionado"
        ;;
    *)
        log_error "Opção inválida"
        exit 1
        ;;
esac

# Confirmação
echo ""
read -p "Continuar com o deploy? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    log_info "Deploy cancelado"
    exit 0
fi

# Parar containers existentes
log_info "Parando containers existentes..."
$DOCKER_COMPOSE -f docker-compose.production.yml down 2>/dev/null || true

# Build da imagem
log_info "Construindo imagem Docker..."
docker build -t morefocus:latest .

# Iniciar serviços
log_info "Iniciando serviços..."
$DOCKER_COMPOSE -f docker-compose.production.yml up -d $PROFILES

# Aguardar inicialização
log_info "Aguardando inicialização..."
sleep 10

# Verificar se está rodando
if docker ps | grep -q morefocus-app; then
    log_success "MoreFocus iniciado com sucesso!"
    
    # Obter informações
    CONTAINER_IP=$(docker inspect morefocus-app --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    HOST_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    echo ""
    echo "🎉 Deploy concluído!"
    echo "=================="
    echo ""
    echo "📋 Informações de acesso:"
    echo "  🌐 URL local: http://localhost:5678/"
    echo "  🌐 URL rede: http://$HOST_IP:5678/"
    echo "  🌐 Webhook: ${WEBHOOK_URL:-http://localhost:5678/}"
    echo "  👤 Usuário: ${N8N_USER:-admin}"
    echo "  🔑 Senha: ${N8N_PASSWORD:-[definida no .env]}"
    echo ""
    
    # Verificar health
    log_info "Verificando saúde da aplicação..."
    sleep 20
    
    if curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
        log_success "Aplicação respondendo corretamente!"
    else
        log_warning "Aplicação ainda inicializando. Aguarde alguns minutos."
    fi
    
    echo ""
    echo "🔗 Webhooks disponíveis:"
    echo "  📊 APQ (Prospecção): ${WEBHOOK_URL:-http://localhost:5678/}webhook/prospeccao"
    echo "  📧 ANE (Nutrição): ${WEBHOOK_URL:-http://localhost:5678/}webhook/nutricao"
    echo "  💰 AVC (Vendas): ${WEBHOOK_URL:-http://localhost:5678/}webhook/vendas"
    echo ""
    
    echo "📋 Próximos passos:"
    echo "  1. Acesse a URL acima"
    echo "  2. Faça login com as credenciais"
    echo "  3. Os workflows já estão importados automaticamente"
    echo "  4. Ative os workflows na interface"
    echo "  5. Configure integrações externas"
    echo ""
    
    echo "🛠️  Comandos úteis:"
    echo "  - Ver logs: docker logs -f morefocus-app"
    echo "  - Parar: $DOCKER_COMPOSE -f docker-compose.production.yml down"
    echo "  - Reiniciar: $DOCKER_COMPOSE -f docker-compose.production.yml restart"
    echo "  - Atualizar: docker pull morefocus:latest && $DOCKER_COMPOSE -f docker-compose.production.yml up -d"
    echo ""
    
    # Salvar informações
    cat > deploy-info.txt << EOF
MoreFocus - Informações do Deploy Docker
=======================================

Data: $(date)
Servidor: $(hostname)
IP: $HOST_IP

Acesso:
- URL: http://$HOST_IP:5678/
- Usuário: ${N8N_USER:-admin}
- Senha: ${N8N_PASSWORD:-[ver arquivo .env]}

Webhooks:
- APQ: ${WEBHOOK_URL:-http://localhost:5678/}webhook/prospeccao
- ANE: ${WEBHOOK_URL:-http://localhost:5678/}webhook/nutricao
- AVC: ${WEBHOOK_URL:-http://localhost:5678/}webhook/vendas

Containers:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

Comandos:
- Logs: docker logs -f morefocus-app
- Parar: $DOCKER_COMPOSE -f docker-compose.production.yml down
- Reiniciar: $DOCKER_COMPOSE -f docker-compose.production.yml restart
EOF
    
    log_success "Informações salvas em: deploy-info.txt"
    
else
    log_error "Falha ao iniciar MoreFocus!"
    echo ""
    echo "🔍 Diagnóstico:"
    echo "  - Logs: docker logs morefocus-app"
    echo "  - Status: docker ps -a"
    echo "  - Compose: $DOCKER_COMPOSE -f docker-compose.production.yml logs"
    exit 1
fi

echo ""
log_success "Deploy Docker concluído! 🎉"

