#!/bin/bash

# MoreFocus - Script de inicializacao para Render (Node.js)
# Solucao alternativa ao Docker

echo "Iniciando MoreFocus (modo Node.js)..."

# Configurar variaveis de ambiente para Render
export N8N_HOST=${N8N_HOST:-0.0.0.0}
export N8N_PORT=${PORT:-10000}
export N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE:-true}
export N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER:-admin}
export N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD:-MoreFocus2024}
export WEBHOOK_URL=${WEBHOOK_URL:-https://morefocus.onrender.com/}
export GENERIC_TIMEZONE=${GENERIC_TIMEZONE:-America/Sao_Paulo}
export DB_TYPE=${DB_TYPE:-sqlite}
export DB_SQLITE_DATABASE=${DB_SQLITE_DATABASE:-~/.n8n/database.sqlite}
export N8N_LOG_LEVEL=${N8N_LOG_LEVEL:-info}
export N8N_DIAGNOSTICS_ENABLED=${N8N_DIAGNOSTICS_ENABLED:-false}
export N8N_VERSION_NOTIFICATIONS_ENABLED=${N8N_VERSION_NOTIFICATIONS_ENABLED:-false}
export N8N_RUNNERS_ENABLED=${N8N_RUNNERS_ENABLED:-true}

# Criar diretorio .n8n
mkdir -p ~/.n8n/workflows

# Copiar workflows se existirem
if [ -d "workflows" ] && [ "$(ls -A workflows/*.json 2>/dev/null)" ]; then
    echo "Importando workflows..."
    cp workflows/*.json ~/.n8n/workflows/ 2>/dev/null || true
fi

echo "Configuracao concluida!"
echo "Porta: $N8N_PORT"
echo "Usuario: $N8N_BASIC_AUTH_USER"

# Iniciar n8n
exec n8n start

