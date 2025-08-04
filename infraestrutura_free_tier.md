# Infraestrutura MoreFocus - Versão AWS Free Tier

## Análise da Infraestrutura Original vs Free Tier

### Situação Atual da Infraestrutura Proposta

A infraestrutura originalmente proposta para a MoreFocus tem um custo mensal de **USD 3.672**, que está significativamente acima dos limites do AWS Free Tier. Vamos analisar os principais componentes e seus custos:

**Custos Originais Mensais:**
- Compute Resources: USD 1.056
- Database & Storage: USD 1.696  
- Networking & CDN: USD 161
- Monitoring & Security: USD 185
- Third-Party Services: USD 574
- **Total: USD 3.672/mês**

### Limitações do AWS Free Tier

O AWS Free Tier oferece recursos limitados por 12 meses para novos usuários:

**Compute (EC2):**
- 750 horas/mês de instâncias t2.micro ou t3.micro
- 1 vCPU, 1 GB RAM por instância
- Apenas para Linux/Windows

**Database (RDS):**
- 750 horas/mês de instâncias db.t2.micro ou db.t3.micro
- 20 GB de armazenamento SSD
- 20 GB de backup

**Storage (S3):**
- 5 GB de armazenamento Standard
- 20.000 GET requests
- 2.000 PUT requests

**Networking:**
- 15 GB de transferência de dados por mês
- 1 milhão de requests HTTP/HTTPS via CloudFront

## Arquitetura Otimizada para Free Tier

### Estratégia de Otimização

Para adequar a MoreFocus ao AWS Free Tier, precisamos adotar uma abordagem híbrida que combine:

1. **Recursos AWS Free Tier** para componentes essenciais
2. **Serviços gratuitos de terceiros** para funcionalidades complementares
3. **Arquitetura serverless** para reduzir custos de compute
4. **Otimização de recursos** para maximizar eficiência

### Arquitetura Proposta para Free Tier

#### 1. Compute Resources - Serverless First

**AWS Lambda (Free Tier: 1M requests/mês + 400.000 GB-segundos):**
```javascript
// Exemplo de função Lambda para n8n webhook
exports.handler = async (event) => {
    const { httpMethod, body, headers } = event;
    
    // Processar webhook do n8n
    if (httpMethod === 'POST') {
        const workflowData = JSON.parse(body);
        
        // Executar lógica de automação
        const result = await processAutomation(workflowData);
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(result)
        };
    }
};
```

**EC2 t3.micro (Free Tier: 750 horas/mês):**
- **Instância única** para n8n self-hosted
- **1 vCPU, 1 GB RAM** - suficiente para workflows básicos
- **Ubuntu 22.04 LTS** para otimização de recursos
- **Docker** para containerização do n8n

#### 2. Database - PostgreSQL Otimizado

**RDS PostgreSQL t3.micro (Free Tier: 750 horas/mês, 20 GB):**
```sql
-- Configuração otimizada para 20 GB
CREATE DATABASE morefocus_lite;

-- Tabelas essenciais com índices otimizados
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    market CHAR(2) NOT NULL, -- 'US', 'EU', 'BR', 'AR'
    tier VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_market ON customers(market);
CREATE INDEX idx_customers_tier ON customers(tier);

-- Tabela de workflows simplificada
CREATE TABLE workflows (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    name VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    config JSONB, -- Configuração do workflow em JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_workflows_customer ON workflows(customer_id);
CREATE INDEX idx_workflows_status ON workflows(status);
```

**Backup Strategy para Free Tier:**
- **Automated backups** incluídos no free tier (20 GB)
- **pg_dump** diário para backup local
- **S3** para backup de configurações (dentro dos 5 GB gratuitos)

#### 3. Storage - S3 + Alternativas Gratuitas

**Amazon S3 (Free Tier: 5 GB):**
- **Configurações n8n**: Backup de workflows
- **Logs críticos**: Apenas logs de erro e auditoria
- **Assets estáticos**: Imagens e documentos essenciais

**GitHub (Gratuito):**
- **Versionamento de workflows**: Controle de versão dos workflows n8n
- **Documentação**: Manuais e procedimentos
- **Backup de código**: Scripts e configurações

```bash
# Script de backup automático para GitHub
#!/bin/bash
# backup_workflows.sh

# Exportar workflows do n8n
curl -X GET "http://localhost:5678/api/v1/workflows" \
  -H "Authorization: Bearer $N8N_API_KEY" \
  -o workflows_backup.json

# Commit para GitHub
git add workflows_backup.json
git commit -m "Automated workflow backup $(date)"
git push origin main
```

#### 4. n8n Configuration - Otimizada para Free Tier

**Docker Compose para EC2 t3.micro:**
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=your-rds-endpoint.amazonaws.com
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=morefocus_lite
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://your-ec2-public-ip:5678/
      - GENERIC_TIMEZONE=America/Sao_Paulo
    volumes:
      - n8n_data:/home/node/.n8n
    deploy:
      resources:
        limits:
          memory: 800M
        reservations:
          memory: 400M

volumes:
  n8n_data:
    driver: local
```

**Otimizações de Performance:**
```javascript
// n8n workflow otimizado para recursos limitados
{
  "name": "Lead Processing Optimized",
  "nodes": [
    {
      "parameters": {
        "batchSize": 10, // Processar em lotes pequenos
        "options": {
          "timeout": 30000 // Timeout reduzido
        }
      },
      "name": "Process Leads",
      "type": "n8n-nodes-base.function"
    }
  ],
  "settings": {
    "executionTimeout": 300, // 5 minutos máximo
    "saveManualExecutions": false, // Economizar espaço
    "callerPolicy": "workflowsFromSameOwner"
  }
}
```

### 5. Serviços Gratuitos de Terceiros

#### Email Marketing - Alternativas Gratuitas

**Mailgun (Free Tier: 5.000 emails/mês):**
```javascript
// Integração n8n com Mailgun
const mailgun = require('mailgun-js')({
  apiKey: 'your-api-key',
  domain: 'your-domain.com'
});

const data = {
  from: 'MoreFocus <noreply@morefocus.com>',
  to: $json.email,
  subject: 'Welcome to MoreFocus',
  template: 'welcome-template',
  'h:X-Mailgun-Variables': JSON.stringify({
    name: $json.name,
    company: $json.company
  })
};

return mailgun.messages().send(data);
```

**Sendinblue/Brevo (Free Tier: 300 emails/dia):**
- **Templates responsivos** incluídos
- **Automação básica** de email marketing
- **Analytics** de abertura e cliques

#### CRM - HubSpot Free

**HubSpot CRM (Gratuito para até 1M contatos):**
```javascript
// Integração n8n com HubSpot
const hubspot = require('@hubspot/api-client');
const hubspotClient = new hubspot.Client({ accessToken: 'your-token' });

const properties = {
  email: $json.email,
  firstname: $json.firstName,
  lastname: $json.lastName,
  company: $json.company,
  lifecyclestage: 'lead'
};

const SimplePublicObjectInput = { properties };

try {
  const apiResponse = await hubspotClient.crm.contacts.basicApi.create(SimplePublicObjectInput);
  return apiResponse;
} catch (e) {
  console.error(e);
}
```

#### Analytics - Google Analytics 4

**GA4 (Gratuito):**
```javascript
// Tracking de eventos customizados
gtag('event', 'workflow_completed', {
  'custom_parameter_1': 'value1',
  'custom_parameter_2': 'value2'
});

// Integração com n8n via Measurement Protocol
const measurement_id = 'G-XXXXXXXXXX';
const api_secret = 'your-api-secret';

const payload = {
  client_id: $json.client_id,
  events: [{
    name: 'automation_executed',
    parameters: {
      workflow_name: $json.workflow_name,
      customer_id: $json.customer_id,
      execution_time: $json.execution_time
    }
  }]
};

return $http.post(`https://www.google-analytics.com/mp/collect?measurement_id=${measurement_id}&api_secret=${api_secret}`, payload);
```

### 6. Monitoramento - Soluções Gratuitas

#### UptimeRobot (Free: 50 monitores)

```bash
# Script de health check para n8n
#!/bin/bash
# health_check.sh

ENDPOINT="http://your-ec2-ip:5678/healthz"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $ENDPOINT)

if [ $RESPONSE -eq 200 ]; then
    echo "n8n is healthy"
    exit 0
else
    echo "n8n is down - HTTP $RESPONSE"
    # Restart n8n container
    docker restart n8n
    exit 1
fi
```

#### Grafana Cloud (Free: 10k séries, 14 dias retenção)

```yaml
# prometheus.yml para métricas básicas
global:
  scrape_interval: 60s

scrape_configs:
  - job_name: 'n8n'
    static_configs:
      - targets: ['localhost:5678']
    metrics_path: '/metrics'
    scrape_interval: 60s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']
```

### 7. Segurança - Implementação Básica

#### SSL/TLS com Let's Encrypt (Gratuito)

```bash
# Configuração Nginx com SSL
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:5678;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### Backup e Segurança

```bash
#!/bin/bash
# security_backup.sh

# Backup do banco de dados
pg_dump -h your-rds-endpoint.amazonaws.com -U postgres morefocus_lite | gzip > backup_$(date +%Y%m%d).sql.gz

# Upload para S3 (dentro do free tier)
aws s3 cp backup_$(date +%Y%m%d).sql.gz s3://your-backup-bucket/

# Manter apenas 7 backups
find . -name "backup_*.sql.gz" -mtime +7 -delete

# Backup de configurações n8n
docker exec n8n n8n export:workflow --all --output=/tmp/workflows.json
aws s3 cp /tmp/workflows.json s3://your-backup-bucket/workflows/
```

## Limitações e Workarounds

### 1. Limitações de Compute

**Problema:** 1 GB RAM pode ser insuficiente para workflows complexos
**Solução:** 
- Processar dados em lotes menores
- Usar Lambda para tarefas específicas
- Implementar cache local com Redis (via Docker)

```javascript
// Workflow otimizado para baixa memória
const batchSize = 10;
const items = $input.all();

for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    await processBatch(batch);
    
    // Limpar memória entre lotes
    if (global.gc) {
        global.gc();
    }
}
```

### 2. Limitações de Storage

**Problema:** 20 GB de banco pode ser insuficiente
**Solução:**
- Arquivar dados antigos para S3
- Usar compressão JSONB para configurações
- Implementar data retention policies

```sql
-- Política de retenção automática
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Arquivar execuções antigas
    DELETE FROM workflow_executions 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Compactar logs
    DELETE FROM logs 
    WHERE created_at < NOW() - INTERVAL '7 days' 
    AND level != 'ERROR';
END;
$$ LANGUAGE plpgsql;

-- Executar limpeza diariamente
SELECT cron.schedule('cleanup-job', '0 2 * * *', 'SELECT cleanup_old_data();');
```

### 3. Limitações de Rede

**Problema:** 15 GB de transferência pode ser insuficiente
**Solução:**
- Comprimir responses HTTP
- Usar CDN gratuito (Cloudflare)
- Otimizar tamanho de payloads

```javascript
// Middleware de compressão
const compression = require('compression');
app.use(compression({
    level: 6,
    threshold: 1024,
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));
```

## Roadmap de Migração para Free Tier

### Fase 1: Setup Básico (Semana 1-2)

1. **Criar conta AWS** e configurar Free Tier
2. **Provisionar EC2 t3.micro** com Ubuntu 22.04
3. **Configurar RDS PostgreSQL** t3.micro
4. **Instalar Docker** e n8n
5. **Configurar domínio** e SSL com Let's Encrypt

### Fase 2: Migração de Workflows (Semana 3-4)

1. **Exportar workflows** da versão atual
2. **Otimizar workflows** para recursos limitados
3. **Testar performance** com dados reais
4. **Configurar monitoramento** básico
5. **Implementar backups** automatizados

### Fase 3: Integração de Serviços (Semana 5-6)

1. **Configurar HubSpot CRM** gratuito
2. **Integrar Mailgun** para emails
3. **Configurar Google Analytics**
4. **Implementar UptimeRobot**
5. **Testar todos os agentes**

### Fase 4: Otimização e Monitoramento (Semana 7-8)

1. **Otimizar performance** do banco
2. **Configurar alertas** críticos
3. **Implementar cache** local
4. **Documentar procedimentos**
5. **Treinar usuários** na nova arquitetura

## Custos da Versão Free Tier

### Custos Mensais Estimados

**AWS Services (Free Tier - 12 meses):**
- EC2 t3.micro: $0 (750 horas incluídas)
- RDS PostgreSQL t3.micro: $0 (750 horas incluídas)
- S3 Storage: $0 (5 GB incluídos)
- Data Transfer: $0 (15 GB incluídos)
- **Subtotal AWS: $0**

**Serviços Gratuitos de Terceiros:**
- HubSpot CRM: $0 (até 1M contatos)
- Mailgun: $0 (5.000 emails/mês)
- UptimeRobot: $0 (50 monitores)
- Let's Encrypt SSL: $0
- **Subtotal Terceiros: $0**

**Custos Opcionais:**
- Domínio (.com): ~$12/ano
- Cloudflare Pro: $20/mês (opcional)
- **Total Opcional: $20-32/mês**

### Comparação de Custos

| Versão | Custo Mensal | Recursos | Escalabilidade |
|--------|--------------|----------|----------------|
| **Original** | $3.672 | Completa | Alta |
| **Free Tier** | $0-32 | Limitada | Baixa |
| **Economia** | $3.640+ | -85% recursos | Limitada |

## Limitações e Considerações

### Limitações Técnicas

1. **Performance:** Significativamente reduzida
2. **Escalabilidade:** Limitada a recursos do free tier
3. **Disponibilidade:** Sem redundância automática
4. **Monitoramento:** Básico, sem APM avançado
5. **Backup:** Manual, sem automação completa

### Limitações de Negócio

1. **Clientes Simultâneos:** Máximo 50-100
2. **Workflows Complexos:** Limitados por memória
3. **Volume de Dados:** Máximo 20 GB no banco
4. **Emails:** Limitado a 5.000/mês
5. **Suporte:** Sem SLA garantido

### Quando Migrar para Infraestrutura Paga

**Indicadores para Upgrade:**
- Mais de 50 clientes ativos
- Receita mensal > $5.000
- Workflows executando > 10.000 vezes/mês
- Necessidade de SLA > 99%
- Compliance rigoroso (SOC2, ISO27001)

**Estratégia de Migração:**
1. **Mês 1-6:** Free Tier para validação
2. **Mês 7-12:** Migração gradual para recursos pagos
3. **Mês 13+:** Infraestrutura completa conforme crescimento

## Conclusão

A versão Free Tier da infraestrutura MoreFocus é **viável para validação inicial** e **primeiros clientes**, oferecendo uma economia de mais de $3.600/mês. No entanto, tem limitações significativas que devem ser consideradas:

**Vantagens:**
- Custo zero ou muito baixo
- Rápida implementação
- Ideal para MVP e validação
- Permite foco no desenvolvimento de produto

**Desvantagens:**
- Performance limitada
- Escalabilidade restrita
- Sem redundância
- Monitoramento básico

**Recomendação:** Usar a versão Free Tier para os **primeiros 3-6 meses** de operação, até atingir receita suficiente para justificar a migração para a infraestrutura completa. Esta abordagem permite validar o modelo de negócio com investimento mínimo em infraestrutura.

