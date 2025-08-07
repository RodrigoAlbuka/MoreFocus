# 🚀 MoreFocus - Deploy no Render

Guia completo para fazer deploy da aplicação MoreFocus no Render.com

## 🎯 Opções de Deploy

### Opção 1: Deploy Docker (Recomendado)
```yaml
# render.yaml
services:
  - type: web
    name: morefocus
    env: docker
    dockerfilePath: ./Dockerfile
```

### Opção 2: Deploy Node.js (Alternativa)
```yaml
# render.yaml
services:
  - type: web
    name: morefocus
    env: node
    buildCommand: npm install -g n8n@latest
    startCommand: ./start.sh
```

## 📋 Passo a Passo

### 1. Preparar Repositório
```bash
# Clonar repositório
git clone https://github.com/RodrigoAlbuka/MoreFocus.git
cd MoreFocus

# Verificar arquivos necessários
ls -la | grep -E "(Dockerfile|render.yaml|package.json|start.sh)"
```

### 2. Configurar no Render

#### Via Dashboard:
1. **Acesse**: https://dashboard.render.com/
2. **New** → **Web Service**
3. **Connect Repository**: https://github.com/RodrigoAlbuka/MoreFocus
4. **Configurações**:
   - **Name**: morefocus
   - **Environment**: Docker
   - **Dockerfile Path**: ./Dockerfile
   - **Plan**: Free

#### Via render.yaml (Automático):
1. **Commit** o arquivo `render.yaml` no repositório
2. **Render detecta** automaticamente
3. **Deploy** inicia automaticamente

### 3. Configurar Variáveis de Ambiente

#### Obrigatórias:
```env
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=SuaSenhaSegura123!
WEBHOOK_URL=https://SEU_APP.onrender.com/
```

#### Opcionais:
```env
N8N_LOG_LEVEL=info
GENERIC_TIMEZONE=America/Sao_Paulo
DB_TYPE=sqlite
```

### 4. Configurar Domínio Personalizado (Opcional)
```yaml
# No render.yaml
customDomains:
  - name: morefocus.com.br
```

## 🔧 Troubleshooting

### Erro: "failed to read dockerfile"

**Problema**: Render não encontra o Dockerfile
**Solução**:
```yaml
# Verificar no render.yaml:
dockerfilePath: ./Dockerfile  # Caminho correto

# Ou usar Node.js:
env: node
buildCommand: npm install -g n8n@latest
startCommand: ./start.sh
```

### Erro: "exit status 1"

**Problema**: Container falha ao iniciar
**Solução**:
```bash
# Verificar logs no Render Dashboard
# Ajustar variáveis de ambiente
# Usar modo Node.js como alternativa
```

### Erro: "Port binding"

**Problema**: Porta incorreta
**Solução**:
```env
# Render usa PORT automaticamente
N8N_PORT=10000  # Ou usar $PORT
N8N_HOST=0.0.0.0
```

## 🌐 Configurações de Produção

### SSL/HTTPS
```env
# Render fornece SSL automaticamente
WEBHOOK_URL=https://morefocus.onrender.com/
N8N_PROTOCOL=https
```

### Banco de Dados
```env
# SQLite (incluído)
DB_TYPE=sqlite
DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite

# PostgreSQL (externo)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=seu-postgres-host
DB_POSTGRESDB_DATABASE=morefocus
DB_POSTGRESDB_USER=postgres
DB_POSTGRESDB_PASSWORD=senha
DB_POSTGRESDB_SSL=true
```

### Persistência de Dados
```yaml
# render.yaml
disk:
  name: morefocus-data
  mountPath: /home/node/.n8n
  sizeGB: 1  # Free tier: 1GB
```

## 📊 Monitoramento

### Health Check
```yaml
# render.yaml
healthCheckPath: /healthz
```

### Logs
```bash
# Via Render CLI
render logs -s morefocus

# Via Dashboard
# Render Dashboard → Service → Logs
```

### Métricas
```bash
# CPU, Memória, Requests
# Disponível no Render Dashboard
```

## 💰 Custos

### Free Tier
- **750 horas/mês**: Gratuito
- **Sleep após 15min**: Inatividade
- **1GB Disk**: Persistente
- **SSL**: Incluído

### Paid Plans
- **Starter ($7/mês)**: Sem sleep
- **Standard ($25/mês)**: Mais recursos
- **Pro ($85/mês)**: Alta performance

## 🔄 CI/CD

### Auto-Deploy
```yaml
# render.yaml
autoDeploy: true  # Deploy automático no push
```

### Deploy Manual
```bash
# Via Render CLI
render deploy -s morefocus

# Via Dashboard
# Manual Deploy → Deploy Latest Commit
```

### Rollback
```bash
# Via Dashboard
# Deployments → Previous Deploy → Rollback
```

## 🚀 Otimizações

### Build Cache
```dockerfile
# Dockerfile
# Usar multi-stage build
# Minimizar layers
# Cache dependencies
```

### Startup Time
```bash
# Reduzir dependências
# Otimizar scripts de inicialização
# Usar imagens menores
```

### Performance
```env
# Configurações otimizadas
N8N_LOG_LEVEL=warn
N8N_DIAGNOSTICS_ENABLED=false
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168
```

## 📞 Suporte

### Render Support
- **Docs**: https://render.com/docs
- **Community**: https://community.render.com/
- **Status**: https://status.render.com/

### MoreFocus Support
- **GitHub**: https://github.com/RodrigoAlbuka/MoreFocus/issues
- **Workflows**: Pasta `/workflows/`
- **Documentação**: README.md

## 🔗 Links Úteis

- **Render Dashboard**: https://dashboard.render.com/
- **Render CLI**: https://render.com/docs/cli
- **n8n Docs**: https://docs.n8n.io/
- **Docker Hub n8n**: https://hub.docker.com/r/n8nio/n8n

---

**MoreFocus** - Automação RPA com agentes de IA 🤖💼

