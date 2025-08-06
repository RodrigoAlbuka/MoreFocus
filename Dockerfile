# MoreFocus - Dockerfile
# Imagem Docker otimizada para deploy em qualquer servidor
# Baseada em Alpine Linux para menor tamanho

FROM node:20-alpine

# Metadados da imagem
LABEL maintainer="MoreFocus Team <morefocusbr@gmail.com>"
LABEL version="1.0.0"
LABEL description="MoreFocus - Automação RPA com n8n e agentes de IA"
LABEL org.opencontainers.image.source="https://github.com/RodrigoAlbuka/MoreFocus"

# Variáveis de ambiente
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

# Instalar dependências do sistema
RUN apk add --no-cache \
    curl \
    wget \
    git \
    bash \
    tzdata \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Configurar timezone
RUN cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone

# Instalar n8n globalmente
RUN npm install -g n8n@latest

# Criar usuário não-root para segurança
RUN addgroup -g 1000 n8n \
    && adduser -u 1000 -G n8n -s /bin/bash -D n8n

# Criar diretórios necessários
RUN mkdir -p /home/n8n/.n8n \
    && mkdir -p /opt/morefocus/workflows \
    && mkdir -p /opt/morefocus/scripts \
    && mkdir -p /opt/morefocus/backups \
    && chown -R n8n:n8n /home/n8n \
    && chown -R n8n:n8n /opt/morefocus

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

# Criar script de health check
RUN cat > /opt/morefocus/healthcheck.sh << 'EOF'
#!/bin/bash

# Health check para n8n
if curl -f http://localhost:5678/healthz > /dev/null 2>&1; then
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

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /opt/morefocus/healthcheck.sh

# Volume para persistência de dados
VOLUME ["/home/n8n/.n8n"]

# Comando de inicialização
CMD ["/opt/morefocus/start.sh"]

