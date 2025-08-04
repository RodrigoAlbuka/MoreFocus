# 🚀 MoreFocus - Guia de Implementação

## 📋 Visão Geral

Este guia detalha como implementar a infraestrutura MoreFocus localmente e na AWS, incluindo a configuração dos 6 agentes de IA baseados em n8n.

## 🏗️ Arquitetura Implementada

### Agentes de IA Criados:
1. **APQ** - Agente de Prospecção e Qualificação
2. **ANE** - Agente de Nutrição e Engajamento  
3. **AVC** - Agente de Vendas e Conversão
4. **AEI** - Agente de Entrega e Implementação
5. **ASC** - Agente de Suporte ao Cliente
6. **AAO** - Agente de Análise e Otimização

### Status Atual:
✅ **Infraestrutura local funcionando**
✅ **n8n rodando com SQLite**
✅ **Workflows criados (3 de 6)**
✅ **Demonstração funcional**
✅ **Scripts de teste**

## 🛠️ Implementação Local (Concluída)

### Pré-requisitos Instalados:
- Docker e Docker Compose
- n8n (versão latest)
- PostgreSQL 14 (opcional)
- Redis 7 (opcional)
- Python 3.11 com bibliotecas

### Serviços Rodando:
```bash
# Verificar status
sudo docker ps

# Logs do n8n
sudo docker logs morefocus-n8n

# Acessar n8n
curl http://localhost:5678/
```

### Credenciais de Acesso:
- **n8n Interface**: http://localhost:5678/
- **Usuário**: admin
- **Senha**: ChangeThisPassword123!

## 📥 Como Importar Workflows no n8n

### 1. Acessar Interface do n8n
```bash
# Abrir no navegador
http://localhost:5678/
```

### 2. Fazer Login
- Usuário: `admin`
- Senha: `ChangeThisPassword123!`

### 3. Importar Workflows
Para cada arquivo JSON em `/workflows/`:

1. Clique em **"+ Add workflow"**
2. Clique no menu **"..."** → **"Import from file"**
3. Selecione o arquivo JSON:
   - `APQ_Agente_Prospeccao.json`
   - `ANE_Agente_Nutricao.json`
   - `AVC_Agente_Vendas.json`
4. Clique em **"Save"**
5. **IMPORTANTE**: Clique no toggle **"Active"** para ativar o workflow

### 4. Configurar Webhooks
Após importar e ativar, os webhooks estarão disponíveis em:
- APQ: `http://localhost:5678/webhook/prospeccao`
- ANE: `http://localhost:5678/webhook/nutricao`
- AVC: `http://localhost:5678/webhook/vendas`

## 🧪 Testes e Validação

### Teste Local (Demonstração)
```bash
# Executar demonstração local
python3 demo_workflows.py

# Resultado esperado:
# ✅ 3 agentes funcionando
# ✅ Fluxo integrado
# ✅ Múltiplos leads processados
```

### Teste HTTP (Após importar workflows)
```bash
# Executar testes HTTP
python3 test_workflows.py

# Resultado esperado:
# ✅ Webhooks respondendo
# ✅ Dados sendo processados
# ✅ Fluxo integrado funcionando
```

### Teste Manual via cURL
```bash
# Testar APQ
curl -X POST http://localhost:5678/webhook/prospeccao \
  -H "Content-Type: application/json" \
  -d '{
    "company": "Teste Corp",
    "email": "teste@corp.com",
    "employees": 100,
    "budget": 10000,
    "urgency": "high"
  }'
```

## ☁️ Implementação na AWS

### Opção 1: Free Tier (Recomendada para início)
```bash
# Usar scripts prontos
./setup_free_tier.sh

# Ou seguir docker-compose-sqlite.yml
sudo docker-compose -f docker-compose-sqlite.yml up -d
```

**Custos**: ~$21/mês (apenas domínio)

### Opção 2: Produção Completa
```bash
# Usar docker-compose.yml original
sudo docker-compose up -d
```

**Custos**: ~$3.672/mês (infraestrutura completa)

### Scripts AWS Disponíveis:
- `setup_free_tier.sh` - Setup automatizado
- `docker-compose-simple.yml` - Versão simplificada
- `docker-compose-sqlite.yml` - Versão SQLite
- `terraform/` - Infraestrutura como código (próxima fase)

## 🔧 Configurações Avançadas

### Variáveis de Ambiente (.env)
```bash
# Editar configurações
nano .env

# Principais variáveis:
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=ChangeThisPassword123!
WEBHOOK_URL=http://localhost:5678/
DB_TYPE=sqlite  # ou postgresdb
```

### Integrações Externas
Para produção, configure:
- **Email**: Mailgun, SendGrid, Amazon SES
- **CRM**: HubSpot, Salesforce, Pipedrive
- **Analytics**: Google Analytics, Mixpanel
- **Pagamentos**: Stripe, PayPal

### Monitoramento
```bash
# Verificar logs
sudo docker logs morefocus-n8n --tail 50

# Verificar recursos
sudo docker stats

# Backup do banco
sudo docker exec morefocus-n8n sqlite3 /home/node/.n8n/database.sqlite ".backup /tmp/backup.db"
```

## 📊 Métricas e KPIs

### Métricas Implementadas:
- **Qualificação de Leads** (APQ)
- **Taxa de Engajamento** (ANE)
- **Probabilidade de Fechamento** (AVC)
- **ROI por Cliente**
- **Tempo de Implementação**

### Dashboard (Próxima Fase):
- Grafana + InfluxDB
- Métricas em tempo real
- Alertas automatizados

## 🚀 Próximos Passos

### Fase Atual: ✅ Concluída
- [x] Infraestrutura local funcionando
- [x] n8n configurado e rodando
- [x] 3 workflows principais criados
- [x] Demonstração funcional
- [x] Scripts de teste

### Próxima Fase: 🔄 Em Andamento
- [ ] Scripts Terraform para AWS
- [ ] 3 workflows restantes (AEI, ASC, AAO)
- [ ] Integrações com serviços externos
- [ ] Dashboard de monitoramento

### Futuras Melhorias:
- [ ] Interface web personalizada
- [ ] Mobile app para monitoramento
- [ ] IA avançada com GPT-4
- [ ] Integração com WhatsApp Business
- [ ] Analytics preditivos

## 🆘 Solução de Problemas

### n8n não inicia:
```bash
# Verificar logs
sudo docker logs morefocus-n8n

# Reiniciar container
sudo docker restart morefocus-n8n

# Recriar do zero
sudo docker-compose down
sudo docker-compose up -d
```

### Webhooks não funcionam:
1. Verificar se workflow está **ativo**
2. Verificar URL do webhook
3. Testar com cURL
4. Verificar logs do n8n

### Problemas de performance:
```bash
# Verificar recursos
sudo docker stats

# Aumentar memória (se necessário)
# Editar docker-compose.yml
deploy:
  resources:
    limits:
      memory: 1G  # Aumentar de 512M
```

### Backup e Restore:
```bash
# Backup
sudo docker exec morefocus-n8n cp /home/node/.n8n/database.sqlite /tmp/
sudo docker cp morefocus-n8n:/tmp/database.sqlite ./backup/

# Restore
sudo docker cp ./backup/database.sqlite morefocus-n8n:/home/node/.n8n/
sudo docker restart morefocus-n8n
```

## 📞 Suporte

### Documentação:
- [n8n Documentation](https://docs.n8n.io/)
- [Docker Documentation](https://docs.docker.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)

### Logs Importantes:
```bash
# n8n logs
sudo docker logs morefocus-n8n

# Sistema
journalctl -u docker

# Recursos
df -h
free -h
```

### Contato:
- 📧 Email: suporte@morefocus.com
- 💬 Chat: Interface do n8n
- 📱 WhatsApp: +55 11 99999-9999

---

## ✅ Status da Implementação

**Infraestrutura**: 100% ✅  
**Workflows**: 50% (3/6) 🔄  
**Testes**: 100% ✅  
**Documentação**: 100% ✅  
**AWS Scripts**: 75% 🔄  

**Próximo Marco**: Completar workflows restantes e scripts AWS

---

*Última atualização: 03/08/2025 20:17*

