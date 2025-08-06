# 🐳 MoreFocus - Deploy Docker

Deploy simplificado da aplicação MoreFocus usando Docker em qualquer servidor.

## 🚀 Quick Start

### 1. Pré-requisitos
```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Instalar Docker Compose (se necessário)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Deploy Automático
```bash
# Clonar repositório
git clone https://github.com/RodrigoAlbuka/MoreFocus.git
cd MoreFocus

# Executar deploy
./docker-deploy.sh
```

### 3. Acesso
- **URL**: http://localhost:5678/
- **Usuário**: admin
- **Senha**: (gerada automaticamente ou definida no .env)

## 📋 Opções de Deploy

### Opção 1: Deploy Básico (SQLite)
```bash
# Apenas MoreFocus com SQLite
docker-compose -f docker-compose.production.yml up -d
```

### Opção 2: Deploy com PostgreSQL
```bash
# MoreFocus + PostgreSQL local
docker-compose -f docker-compose.production.yml --profile postgres up -d
```

### Opção 3: Deploy com Redis
```bash
# MoreFocus + Redis para cache
docker-compose -f docker-compose.production.yml --profile redis up -d
```

### Opção 4: Deploy Completo
```bash
# MoreFocus + PostgreSQL + Redis + SSL
docker-compose -f docker-compose.production.yml --profile postgres --profile redis --profile ssl up -d
```

## ⚙️ Configuração

### Arquivo .env
```bash
# Copiar exemplo
cp .env.example .env

# Editar configurações
nano .env
```

### Variáveis Principais
```env
# Credenciais (OBRIGATÓRIO)
N8N_USER=admin
N8N_PASSWORD=SuaSenhaSegura123!

# Webhook URL (substitua pelo seu IP/domínio)
WEBHOOK_URL=http://SEU_IP:5678/

# Banco de dados
DB_TYPE=sqlite  # ou postgresdb

# Para PostgreSQL/Supabase
DB_HOST=db.supabase.co
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=sua_senha
DB_SSL=true
```

## 🔧 Comandos Úteis

### Gerenciamento
```bash
# Ver logs
docker logs -f morefocus-app

# Parar serviços
docker-compose -f docker-compose.production.yml down

# Reiniciar
docker-compose -f docker-compose.production.yml restart

# Atualizar
git pull
docker build -t morefocus:latest .
docker-compose -f docker-compose.production.yml up -d
```

### Backup
```bash
# Backup dos dados
docker run --rm -v morefocus_morefocus_data:/data -v $(pwd):/backup alpine tar czf /backup/morefocus-backup.tar.gz -C /data .

# Restaurar backup
docker run --rm -v morefocus_morefocus_data:/data -v $(pwd):/backup alpine tar xzf /backup/morefocus-backup.tar.gz -C /data
```

### Monitoramento
```bash
# Status dos containers
docker ps

# Uso de recursos
docker stats

# Health check
curl http://localhost:5678/healthz
```

## 🌐 Deploy em Diferentes Ambientes

### VPS/Servidor Dedicado
```bash
# 1. Configurar firewall
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 5678  # n8n
sudo ufw enable

# 2. Configurar .env com IP público
WEBHOOK_URL=http://SEU_IP_PUBLICO:5678/

# 3. Deploy
./docker-deploy.sh
```

### Cloud (AWS, GCP, Azure)
```bash
# 1. Instalar Docker na instância
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 2. Configurar Security Groups/Firewall
# Liberar portas: 22, 80, 443, 5678

# 3. Deploy com IP público
WEBHOOK_URL=http://IP_PUBLICO:5678/
./docker-deploy.sh
```

### Localhost/Desenvolvimento
```bash
# Configuração para desenvolvimento local
cp .env.example .env
# Editar: WEBHOOK_URL=http://localhost:5678/
./docker-deploy.sh
```

## 🔒 Configuração SSL (Opcional)

### 1. Certificado Let's Encrypt
```bash
# Instalar certbot
sudo apt install certbot

# Gerar certificado
sudo certbot certonly --standalone -d seudominio.com

# Copiar certificados
sudo cp /etc/letsencrypt/live/seudominio.com/fullchain.pem ./nginx/ssl/
sudo cp /etc/letsencrypt/live/seudominio.com/privkey.pem ./nginx/ssl/
```

### 2. Configurar Nginx
```bash
# Criar configuração SSL
mkdir -p nginx
cat > nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream morefocus {
        server morefocus:5678;
    }

    server {
        listen 443 ssl;
        server_name seudominio.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        location / {
            proxy_pass http://morefocus;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }

    server {
        listen 80;
        server_name seudominio.com;
        return 301 https://$server_name$request_uri;
    }
}
EOF

# Deploy com SSL
docker-compose -f docker-compose.production.yml --profile ssl up -d
```

## 🔍 Troubleshooting

### Container não inicia
```bash
# Ver logs detalhados
docker logs morefocus-app

# Verificar configuração
docker inspect morefocus-app

# Testar conectividade de rede
docker exec morefocus-app ping google.com
```

### Banco de dados não conecta
```bash
# Testar conexão PostgreSQL
docker exec morefocus-app nc -zv DB_HOST 5432

# Ver logs de conexão
docker logs morefocus-app | grep -i database
```

### Webhooks não funcionam
```bash
# Verificar URL configurada
docker exec morefocus-app env | grep WEBHOOK_URL

# Testar webhook
curl -X POST http://localhost:5678/webhook/test
```

### Performance
```bash
# Monitorar recursos
docker stats morefocus-app

# Ajustar limites de memória
# Editar docker-compose.production.yml:
# deploy.resources.limits.memory: "2G"
```

## 📊 Monitoramento

### Health Checks
```bash
# Status da aplicação
curl http://localhost:5678/healthz

# Métricas básicas
curl http://localhost:5678/metrics
```

### Logs Estruturados
```bash
# Logs em tempo real
docker logs -f morefocus-app

# Logs com timestamp
docker logs -t morefocus-app

# Últimas 100 linhas
docker logs --tail 100 morefocus-app
```

## 🚀 Escalabilidade

### Load Balancer
```bash
# Múltiplas instâncias
docker-compose -f docker-compose.production.yml up -d --scale morefocus=3

# Nginx como load balancer
# Configurar upstream com múltiplos servers
```

### Cluster Docker Swarm
```bash
# Inicializar swarm
docker swarm init

# Deploy como stack
docker stack deploy -c docker-compose.production.yml morefocus
```

## 💰 Custos Estimados

### Servidor VPS
- **1 CPU, 1GB RAM**: $5-10/mês
- **2 CPU, 2GB RAM**: $10-20/mês
- **4 CPU, 4GB RAM**: $20-40/mês

### Cloud
- **AWS t3.micro**: Gratuito (Free Tier)
- **GCP e1-micro**: Gratuito (Free Tier)
- **Azure B1s**: ~$15/mês

## 📞 Suporte

- **Documentação**: [README.md](README.md)
- **Issues**: https://github.com/RodrigoAlbuka/MoreFocus/issues
- **Workflows**: Pasta `/workflows/`

---

**MoreFocus** - Automação RPA com agentes de IA 🤖💼

