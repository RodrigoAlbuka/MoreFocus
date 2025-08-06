# MoreFocus - Dockerfile
# Imagem Docker otimizada baseada na imagem oficial do n8n
# Compatível com ambientes que têm limitações de iptables

FROM n8nio/n8n:latest

# Metadados da imagem
LABEL maintainer="MoreFocus Team <morefocusbr@gmail.com>"
LABEL version="1.0.1"
LABEL description="MoreFocus - Automação RPA com n8n e agentes de IA"
LABEL org.opencontainers.image.source="https://github.com/RodrigoAlbuka/MoreFocus"

# Usar usuário root temporariamente para configurações
USER root

# Instalar dependências básicas (usando apt em vez de apk)
RUN apt-get update && apt-get install -y \
    wget \
    git \
    bash \
    netcat-openbsd \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Variáveis de ambiente otimizadas
ENV NODE_ENV=production
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV N8N_PROTOCOL=http
ENV GENERIC_TIMEZONE=America/Sao_Paulo
ENV N8N_LOG_LEVEL=info
ENV N8N_DIAGNOSTICS_ENABLED=false
ENV N8N_VERSION_NOTIFICATIONS_ENABLED=false
ENV N8N_TEMPLATES_ENABLED=true
ENV N8N_ONBOARDING_FLOW_DISABLED=false
ENV EXECUTIONS_DATA_PRUNE=true
ENV EXECUTIONS_DATA_MAX_AGE=168
ENV N8N_RUNNERS_ENABLED=true
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=false

# Criar diretórios necessários
RUN mkdir -p /opt/morefocus/workflows \
    && mkdir -p /opt/morefocus/scripts \
    && mkdir -p /opt/morefocus/backups

# Copiar arquivos da aplicação
COPY --chown=n8n:n8n workflows/ /opt/morefocus/workflows/
COPY --chown=n8n:n8n *.sh /opt/morefocus/scripts/
COPY --chown=n8n:n8n *.md /opt/morefocus/
COPY --chown=n8n:n8n index.html /opt/morefocus/

# Criar script de inicialização
RUN cat > /opt/morefocus/start.sh << 'EOF'
#!/bin/bash

# MoreFocus - Script de Inicialização
set -e

echo "🚀 Iniciando MoreFocus..."
echo "=========================="

# Verificar variáveis obrigatórias
if [ -z "$N8N_BASIC_AUTH_USER" ]; then
    echo "❌ Erro: N8N_BASIC_AUTH_USER não definido"
    exit 1
fi

if [ -z "$N8N_BASIC_AUTH_PASSWORD" ]; then
    echo "❌ Erro: N8N_BASIC_AUTH_PASSWORD não definido"
    exit 1
fi

# Configurar autenticação básica
export N8N_BASIC_AUTH_ACTIVE=true

# Configurar webhook URL se não definida
if [ -z "$WEBHOOK_URL" ]; then
    export WEBHOOK_URL="http://localhost:5678/"
    echo "⚠️  WEBHOOK_URL não definida, usando: $WEBHOOK_URL"
fi

# Configurar banco de dados se não definido
if [ -z "$DB_TYPE" ]; then
    export DB_TYPE=sqlite
    export DB_SQLITE_DATABASE=/home/n8n/.n8n/database.sqlite
    echo "📄 Usando SQLite como banco de dados"
else
    echo "🗄️  Usando banco: $DB_TYPE"
fi

# Mostrar configuração
echo ""
echo "📋 Configuração:"
echo "  - Usuário: $N8N_BASIC_AUTH_USER"
echo "  - Host: $N8N_HOST:$N8N_PORT"
echo "  - Webhook: $WEBHOOK_URL"
echo "  - Database: $DB_TYPE"
echo "  - Timezone: $GENERIC_TIMEZONE"
echo ""

# Aguardar banco de dados se PostgreSQL
if [ "$DB_TYPE" = "postgresdb" ] && [ -n "$DB_POSTGRESDB_HOST" ]; then
    echo "⏳ Aguardando banco PostgreSQL..."
    
    for i in {1..30}; do
        if nc -z "$DB_POSTGRESDB_HOST" "${DB_POSTGRESDB_PORT:-5432}" 2>/dev/null; then
            echo "✅ Banco PostgreSQL conectado!"
            break
        fi
        
        if [ $i -eq 30 ]; then
            echo "❌ Timeout conectando ao PostgreSQL"
            exit 1
        fi
        
        echo "  Tentativa $i/30..."
        sleep 2
    done
fi

# Criar diretório de workflows se não existir
mkdir -p /home/n8n/.n8n/workflows

# Importar workflows se existirem
if [ -d "/opt/morefocus/workflows" ] && [ "$(ls -A /opt/morefocus/workflows/*.json 2>/dev/null)" ]; then
    echo "📥 Workflows encontrados:"
    for workflow in /opt/morefocus/workflows/*.json; do
        if [ -f "$workflow" ]; then
            echo "  - $(basename "$workflow")"
            cp "$workflow" /home/n8n/.n8n/workflows/
        fi
    done
    echo "✅ Workflows copiados para /home/n8n/.n8n/workflows/"
fi

# Configurar permissões
chown -R n8n:n8n /home/n8n/.n8n

echo ""
echo "🎯 Iniciando n8n..."
echo "==================="

# Iniciar n8n
exec n8n start
EOF

# Tornar script executável
RUN chmod +x /opt/morefocus/start.sh

# Criar script de health check (usando wget em vez de curl)
RUN cat > /opt/morefocus/healthcheck.sh << 'EOF'
#!/bin/bash

# Health check para n8n usando wget
if wget --quiet --tries=1 --spider http://localhost:5678/healthz > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
EOF

RUN chmod +x /opt/morefocus/healthcheck.sh

# Mudar para usuário n8n
USER n8n

# Definir diretório de trabalho
WORKDIR /home/n8n

# Expor porta
EXPOSE 5678

# Health check usando wget
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:5678/healthz || exit 1

# Volume para persistência de dados
VOLUME ["/home/n8n/.n8n"]

# Comando de inicialização
CMD ["/opt/morefocus/start.sh"]

