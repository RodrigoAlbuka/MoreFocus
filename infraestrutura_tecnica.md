# Infraestrutura Técnica e Operacional - MoreFocus

## Visão Geral da Arquitetura

A infraestrutura da MoreFocus foi projetada para suportar operações globais completamente automatizadas, garantindo alta disponibilidade, escalabilidade e compliance regulatório em todos os mercados-alvo. A arquitetura segue princípios de cloud-native, microserviços e infraestrutura como código (IaC).

## Arquitetura Cloud Multi-Região

### Distribuição Geográfica

A MoreFocus opera em uma arquitetura multi-região para garantir baixa latência e compliance local:

**Região Primária - Estados Unidos (us-east-1):**
- Datacenter principal em Virginia, AWS
- Serve clientes dos EUA e Canadá
- Hub central de coordenação global
- Backup primário de todos os dados

**Região Secundária - Europa (eu-west-1):**
- Datacenter em Dublin, AWS
- Serve clientes europeus (GDPR compliance)
- Replicação síncrona de dados críticos
- Failover automático para região primária

**Região Terciária - América do Sul (sa-east-1):**
- Datacenter em São Paulo, AWS
- Serve clientes do Brasil e Argentina
- Otimização para latência regional
- Compliance com LGPD brasileira

### Componentes de Infraestrutura

**Compute Resources:**
- **Amazon EKS (Elastic Kubernetes Service)**: Orquestração de containers
- **EC2 Instances**: t3.large para workloads padrão, c5.xlarge para processamento intensivo
- **Auto Scaling Groups**: Escalabilidade automática baseada em métricas
- **Spot Instances**: 30% dos recursos para otimização de custos

**Storage Solutions:**
- **Amazon RDS PostgreSQL**: Banco de dados principal com Multi-AZ
- **Amazon ElastiCache Redis**: Cache distribuído para sessões e dados temporários
- **Amazon S3**: Armazenamento de objetos para backups e arquivos
- **Amazon EFS**: Sistema de arquivos compartilhado para containers

**Networking:**
- **Amazon VPC**: Redes privadas virtuais por região
- **AWS Transit Gateway**: Conectividade entre regiões
- **Application Load Balancer**: Distribuição de carga com SSL termination
- **CloudFront CDN**: Distribuição global de conteúdo estático

## Stack Tecnológico Detalhado

### Plataforma de Automação

**n8n Self-Hosted:**
- **Versão**: n8n 1.0+ (self-hosted para controle total)
- **Node.js**: Versão 20.19 (compatibilidade garantida)
- **Deployment**: Kubernetes pods com persistent volumes
- **Scaling**: Horizontal pod autoscaler baseado em CPU/memória
- **High Availability**: 3 réplicas por região com load balancing

**Configuração n8n:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: n8n-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: n8n
  template:
    metadata:
      labels:
        app: n8n
    spec:
      containers:
      - name: n8n
        image: n8nio/n8n:latest
        ports:
        - containerPort: 5678
        env:
        - name: DB_TYPE
          value: "postgresdb"
        - name: DB_POSTGRESDB_HOST
          value: "postgres-service"
        - name: N8N_BASIC_AUTH_ACTIVE
          value: "true"
        - name: N8N_ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: n8n-secrets
              key: encryption-key
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
```

### Banco de Dados e Persistência

**PostgreSQL 14+ Configuration:**
- **Instance Type**: db.r5.xlarge (4 vCPU, 32 GB RAM)
- **Storage**: 1TB SSD com auto-scaling até 10TB
- **Backup**: Automated backups com 30 dias de retenção
- **Read Replicas**: 2 réplicas de leitura por região
- **Encryption**: AES-256 encryption at rest e in transit

**Schema Design:**
```sql
-- Tabela principal de clientes
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    market VARCHAR(50) NOT NULL, -- 'US', 'EU', 'BR', 'AR'
    tier VARCHAR(50) NOT NULL, -- 'starter', 'professional', 'enterprise'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de automações implementadas
CREATE TABLE automations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id),
    workflow_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    roi_projected DECIMAL(10,2),
    roi_actual DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de métricas de performance
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    automation_id UUID REFERENCES automations(id),
    metric_type VARCHAR(100) NOT NULL,
    value DECIMAL(15,4) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Redis Configuration:**
- **Instance Type**: cache.r5.large (2 vCPU, 13 GB RAM)
- **Cluster Mode**: Enabled com 3 shards
- **Replication**: 1 réplica por shard
- **Use Cases**: Session storage, workflow cache, rate limiting

### Monitoramento e Observabilidade

**Prometheus Stack:**
- **Prometheus**: Coleta de métricas de todos os componentes
- **Grafana**: Dashboards executivos e técnicos
- **AlertManager**: Alertas inteligentes com escalação
- **Node Exporter**: Métricas de infraestrutura
- **Custom Metrics**: Métricas de negócio específicas

**Logging Stack (ELK):**
- **Elasticsearch**: Armazenamento e indexação de logs
- **Logstash**: Processamento e transformação de logs
- **Kibana**: Visualização e análise de logs
- **Filebeat**: Coleta de logs dos containers

**Application Performance Monitoring:**
- **New Relic**: APM para aplicações Node.js
- **DataDog**: Monitoramento de infraestrutura
- **Sentry**: Error tracking e performance monitoring
- **Uptime Robot**: Monitoramento de disponibilidade externa

### Segurança e Compliance

**Identity and Access Management:**
- **AWS IAM**: Controle de acesso granular
- **AWS Secrets Manager**: Gerenciamento seguro de credenciais
- **HashiCorp Vault**: Secrets management para aplicações
- **Multi-Factor Authentication**: Obrigatório para todos os acessos

**Network Security:**
- **AWS WAF**: Web Application Firewall
- **AWS Shield**: Proteção contra DDoS
- **VPC Security Groups**: Firewall de instância
- **Network ACLs**: Firewall de subnet

**Data Protection:**
- **Encryption at Rest**: AES-256 para todos os dados
- **Encryption in Transit**: TLS 1.3 para todas as comunicações
- **Key Management**: AWS KMS com rotação automática
- **Data Loss Prevention**: Políticas automatizadas de proteção

**Compliance Frameworks:**
- **GDPR**: Para clientes europeus
- **LGPD**: Para clientes brasileiros
- **SOC 2 Type II**: Certificação de segurança
- **ISO 27001**: Gestão de segurança da informação
- **PCI DSS**: Para processamento de pagamentos

## Integração e APIs

### API Gateway Architecture

**Amazon API Gateway:**
- **Rate Limiting**: 1000 requests/minute por cliente
- **Authentication**: JWT tokens com refresh automático
- **Throttling**: Proteção contra abuse
- **Caching**: Cache de respostas por 5 minutos
- **Monitoring**: Métricas detalhadas de uso

**API Design Principles:**
- **RESTful**: Seguindo padrões REST
- **Versioning**: Versionamento semântico (v1, v2)
- **Documentation**: OpenAPI 3.0 specification
- **Testing**: Testes automatizados para todas as APIs
- **Security**: OAuth 2.0 + PKCE para autenticação

### Integrações Externas

**CRM Systems:**
- **HubSpot API**: Sincronização de leads e clientes
- **Salesforce API**: Para clientes enterprise
- **Pipedrive API**: Para mercados emergentes
- **RD Station API**: Para mercado brasileiro

**Payment Processors:**
- **Stripe API**: Processamento global de pagamentos
- **Mercado Pago API**: América Latina
- **PayPal API**: Backup global
- **Banco do Brasil API**: Open Banking Brasil

**Communication Platforms:**
- **WhatsApp Business API**: Comunicação no Brasil/Argentina
- **Slack API**: Notificações internas
- **Microsoft Teams API**: Integração com clientes enterprise
- **Zoom API**: Webinars e demonstrações

**AI and ML Services:**
- **OpenAI GPT-4 API**: Geração de conteúdo e chatbots
- **Google Cloud Translation API**: Tradução automática
- **AWS Comprehend**: Análise de sentimento
- **Dialogflow**: Processamento de linguagem natural

## DevOps e CI/CD

### Continuous Integration/Continuous Deployment

**GitLab CI/CD Pipeline:**
```yaml
stages:
  - test
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_REGISTRY: "registry.gitlab.com/morefocus"
  KUBERNETES_NAMESPACE: "morefocus-prod"

test:
  stage: test
  script:
    - npm install
    - npm run test
    - npm run lint
  coverage: '/Coverage: \d+\.\d+%/'

build:
  stage: build
  script:
    - docker build -t $DOCKER_REGISTRY/n8n-custom:$CI_COMMIT_SHA .
    - docker push $DOCKER_REGISTRY/n8n-custom:$CI_COMMIT_SHA
  only:
    - main

deploy-production:
  stage: deploy-production
  script:
    - kubectl set image deployment/n8n-deployment n8n=$DOCKER_REGISTRY/n8n-custom:$CI_COMMIT_SHA
    - kubectl rollout status deployment/n8n-deployment
  environment:
    name: production
  only:
    - main
```

**Infrastructure as Code (Terraform):**
```hcl
# VPC Configuration
resource "aws_vpc" "morefocus_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "morefocus-vpc"
    Environment = var.environment
  }
}

# EKS Cluster
resource "aws_eks_cluster" "morefocus_cluster" {
  name     = "morefocus-${var.environment}"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.27"

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# RDS PostgreSQL
resource "aws_db_instance" "morefocus_db" {
  identifier = "morefocus-${var.environment}"
  engine     = "postgres"
  engine_version = "14.9"
  instance_class = "db.r5.xlarge"
  allocated_storage = 1000
  max_allocated_storage = 10000
  
  db_name  = "morefocus"
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.morefocus.name
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  encryption_at_rest = true
  
  tags = {
    Name = "morefocus-db-${var.environment}"
  }
}
```

### Deployment Strategy

**Blue-Green Deployment:**
- **Zero Downtime**: Deployments sem interrupção de serviço
- **Rollback Rápido**: Rollback em menos de 2 minutos
- **Testing**: Testes automatizados em ambiente blue antes do switch
- **Monitoring**: Monitoramento contínuo durante deployment

**Canary Releases:**
- **Gradual Rollout**: 5% → 25% → 50% → 100%
- **Automated Rollback**: Rollback automático se métricas degradarem
- **A/B Testing**: Comparação de performance entre versões
- **Feature Flags**: Controle granular de funcionalidades

## Backup e Disaster Recovery

### Estratégia de Backup

**Database Backups:**
- **Automated Backups**: Backup automático a cada 6 horas
- **Point-in-Time Recovery**: Recuperação para qualquer momento nos últimos 30 dias
- **Cross-Region Replication**: Backup replicado em 3 regiões
- **Encryption**: Todos os backups criptografados com AES-256

**Application Backups:**
- **Configuration Backup**: Backup diário de configurações n8n
- **Workflow Backup**: Versionamento de todos os workflows
- **Secrets Backup**: Backup seguro de credenciais e tokens
- **Infrastructure Backup**: Snapshots de infraestrutura via Terraform

### Disaster Recovery Plan

**Recovery Time Objectives (RTO):**
- **Falha de Região**: 4 horas para failover completo
- **Falha de Aplicação**: 15 minutos para restart automático
- **Falha de Banco**: 30 minutos para failover de read replica
- **Falha de Rede**: 5 minutos para rerouting automático

**Recovery Point Objectives (RPO):**
- **Dados Críticos**: Máximo 15 minutos de perda
- **Configurações**: Máximo 1 hora de perda
- **Logs**: Máximo 5 minutos de perda
- **Métricas**: Máximo 1 minuto de perda

**Disaster Recovery Procedures:**
1. **Detecção Automática**: Alertas automáticos para falhas críticas
2. **Escalação**: Notificação imediata para equipe de resposta
3. **Failover**: Processo automatizado de failover
4. **Comunicação**: Notificação automática para clientes afetados
5. **Recovery**: Procedimentos de recuperação documentados
6. **Post-Mortem**: Análise e melhoria contínua dos processos


## Custos Operacionais Detalhados

### Breakdown de Custos Mensais (USD)

**Compute Resources:**
| Serviço | Especificação | Quantidade | Custo Unitário | Total Mensal |
|---------|---------------|------------|----------------|--------------|
| EKS Cluster | Control Plane | 3 regiões | $72/região | $216 |
| EC2 Instances | t3.large | 6 instâncias | $67/instância | $402 |
| EC2 Instances | c5.xlarge | 3 instâncias | $146/instância | $438 |
| **Subtotal Compute** | | | | **$1.056** |

**Database & Storage:**
| Serviço | Especificação | Quantidade | Custo Unitário | Total Mensal |
|---------|---------------|------------|----------------|--------------|
| RDS PostgreSQL | db.r5.xlarge | 3 instâncias | $285/instância | $855 |
| ElastiCache Redis | cache.r5.large | 3 clusters | $142/cluster | $426 |
| S3 Storage | Standard | 5TB | $0.023/GB | $115 |
| EFS Storage | Standard | 1TB | $0.30/GB | $300 |
| **Subtotal Storage** | | | | **$1.696** |

**Networking & CDN:**
| Serviço | Especificação | Quantidade | Custo Unitário | Total Mensal |
|---------|---------------|------------|----------------|--------------|
| Application Load Balancer | 3 regiões | 3 ALBs | $22/ALB | $66 |
| CloudFront CDN | Global | 1TB transfer | $0.085/GB | $85 |
| Data Transfer | Inter-region | 500GB | $0.02/GB | $10 |
| **Subtotal Networking** | | | | **$161** |

**Monitoring & Security:**
| Serviço | Especificação | Quantidade | Custo Unitário | Total Mensal |
|---------|---------------|------------|----------------|--------------|
| CloudWatch | Logs + Metrics | Standard | - | $150 |
| AWS WAF | Web ACL | 3 regiões | $5/região | $15 |
| Secrets Manager | 50 secrets | 50 secrets | $0.40/secret | $20 |
| Certificate Manager | SSL Certs | Included | $0 | $0 |
| **Subtotal Monitoring** | | | | **$185** |

**Third-Party Services:**
| Serviço | Especificação | Quantidade | Custo Unitário | Total Mensal |
|---------|---------------|------------|----------------|--------------|
| New Relic | APM Pro | 10 hosts | $25/host | $250 |
| DataDog | Infrastructure | 15 hosts | $15/host | $225 |
| GitLab CI/CD | Premium | 1 license | $99 | $99 |
| **Subtotal Third-Party** | | | | **$574** |

**Total Infraestrutura Mensal: $3.672**

### Otimização de Custos

**Reserved Instances (RI):**
- **Economia**: 40% em instâncias EC2 com RI de 1 ano
- **Savings Plans**: 20% adicional em compute com commitment
- **Spot Instances**: 30% dos workloads em spot para 60% de economia

**Auto Scaling:**
- **Scale Down**: Redução automática durante baixa demanda
- **Scheduled Scaling**: Ajuste baseado em padrões de uso
- **Predictive Scaling**: ML para prever demanda futura

**Storage Optimization:**
- **S3 Intelligent Tiering**: Movimentação automática entre classes
- **EBS GP3**: Migração para volumes mais eficientes
- **Lifecycle Policies**: Arquivamento automático de dados antigos

**Projeção de Economia:**
- **Ano 1**: $3.672/mês (baseline)
- **Ano 2**: $2.938/mês (20% economia com otimizações)
- **Ano 3**: $2.572/mês (30% economia com reserved instances)

## Especificações de Performance

### SLAs (Service Level Agreements)

**Disponibilidade:**
- **Uptime Target**: 99.9% (8.76 horas de downtime/ano)
- **Planned Maintenance**: Máximo 4 horas/mês
- **Unplanned Downtime**: Máximo 2 horas/mês
- **Regional Failover**: Automático em <5 minutos

**Performance:**
- **Response Time**: <200ms para 95% das requests
- **Throughput**: 1000 requests/segundo por região
- **Concurrent Users**: 10.000 usuários simultâneos
- **Data Processing**: 1M records/hora por workflow

**Escalabilidade:**
- **Horizontal Scaling**: Automático baseado em CPU/memória
- **Vertical Scaling**: Manual para workloads específicos
- **Geographic Scaling**: Expansão para novas regiões em 30 dias
- **Capacity Planning**: Revisão trimestral de capacidade

### Métricas de Monitoramento

**Infrastructure Metrics:**
```yaml
# Prometheus Alerting Rules
groups:
- name: infrastructure
  rules:
  - alert: HighCPUUsage
    expr: cpu_usage_percent > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      
  - alert: HighMemoryUsage
    expr: memory_usage_percent > 85
    for: 5m
    labels:
      severity: warning
      
  - alert: DatabaseConnectionsHigh
    expr: postgres_connections > 80
    for: 2m
    labels:
      severity: critical
```

**Application Metrics:**
- **Workflow Execution Time**: Tempo médio de execução por workflow
- **Error Rate**: Taxa de erro por agente (<1% target)
- **Queue Depth**: Profundidade da fila de processamento
- **API Latency**: Latência das APIs externas

**Business Metrics:**
- **Lead Processing Rate**: Leads processados por hora
- **Conversion Rate**: Taxa de conversão por funil
- **Customer Satisfaction**: CSAT score automático
- **Revenue per Customer**: Receita média por cliente

## Segurança Avançada

### Zero Trust Architecture

**Princípios Implementados:**
- **Never Trust, Always Verify**: Verificação contínua de identidade
- **Least Privilege Access**: Acesso mínimo necessário
- **Assume Breach**: Arquitetura resiliente a compromissos
- **Continuous Monitoring**: Monitoramento 24/7 de atividades

**Implementation Details:**
```yaml
# Network Policies (Kubernetes)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### Data Encryption

**Encryption at Rest:**
- **Database**: AES-256 encryption para PostgreSQL
- **Storage**: S3 server-side encryption com KMS
- **Backups**: Encrypted backups com customer-managed keys
- **Logs**: Encrypted log storage com retention policies

**Encryption in Transit:**
- **TLS 1.3**: Para todas as comunicações externas
- **mTLS**: Para comunicação entre microserviços
- **VPN**: Site-to-site VPN para conexões administrativas
- **Certificate Management**: Automated certificate rotation

### Compliance Automation

**GDPR Compliance:**
```python
# Automated GDPR Data Processing
class GDPRProcessor:
    def __init__(self):
        self.data_retention_days = 365
        self.anonymization_fields = ['email', 'phone', 'ip_address']
    
    def process_deletion_request(self, customer_id):
        # Automated data deletion
        self.delete_customer_data(customer_id)
        self.anonymize_logs(customer_id)
        self.update_audit_trail(customer_id, 'DELETED')
    
    def generate_data_export(self, customer_id):
        # Automated data export for GDPR requests
        customer_data = self.extract_customer_data(customer_id)
        return self.format_gdpr_export(customer_data)
```

**SOC 2 Controls:**
- **Access Controls**: Automated user provisioning/deprovisioning
- **Change Management**: All changes tracked and approved
- **Monitoring**: Continuous monitoring of security controls
- **Incident Response**: Automated incident detection and response

## Escalabilidade e Crescimento

### Horizontal Scaling Strategy

**Microservices Architecture:**
- **Service Decomposition**: Cada agente como microserviço independente
- **API Gateway**: Roteamento inteligente entre serviços
- **Service Mesh**: Istio para comunicação segura entre serviços
- **Circuit Breakers**: Proteção contra cascading failures

**Database Scaling:**
- **Read Replicas**: Scaling de leitura com múltiplas réplicas
- **Sharding**: Particionamento horizontal por região/cliente
- **Connection Pooling**: PgBouncer para otimização de conexões
- **Query Optimization**: Índices automáticos baseados em uso

### Capacity Planning

**Growth Projections:**
| Métrica | Mês 1 | Mês 6 | Mês 12 | Mês 24 |
|---------|-------|-------|--------|--------|
| Clientes Ativos | 8 | 48 | 96 | 200 |
| Workflows Ativos | 50 | 300 | 600 | 1.250 |
| Execuções/Dia | 1.000 | 6.000 | 12.000 | 25.000 |
| Dados Processados (GB/dia) | 10 | 60 | 120 | 250 |

**Infrastructure Scaling:**
- **Compute**: Auto-scaling de 6 para 50 instâncias
- **Storage**: Crescimento de 5TB para 100TB
- **Network**: Bandwidth de 1Gbps para 10Gbps
- **Database**: Scaling vertical e horizontal conforme demanda

### Multi-Tenant Architecture

**Tenant Isolation:**
- **Database**: Schema separation por cliente
- **Compute**: Namespace isolation no Kubernetes
- **Storage**: Bucket separation no S3
- **Network**: VLAN separation para clientes enterprise

**Resource Allocation:**
```yaml
# Kubernetes Resource Quotas per Tenant
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-namespace
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "10"
    services: "5"
```

## Operações e Manutenção

### Automated Operations

**Self-Healing Systems:**
- **Health Checks**: Verificações automáticas de saúde
- **Auto-Restart**: Restart automático de serviços falhos
- **Failover**: Failover automático para instâncias saudáveis
- **Recovery**: Recuperação automática de dados corrompidos

**Maintenance Automation:**
- **Patch Management**: Aplicação automática de patches de segurança
- **Backup Verification**: Verificação automática de integridade de backups
- **Performance Tuning**: Otimização automática baseada em métricas
- **Capacity Management**: Ajuste automático de recursos

### 24/7 Monitoring

**Alerting Strategy:**
```yaml
# AlertManager Configuration
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@morefocus.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'https://hooks.slack.com/services/...'
    send_resolved: true
```

**Incident Response:**
1. **Detection**: Automated detection via monitoring
2. **Triage**: Automated severity classification
3. **Escalation**: Escalation matrix based on severity
4. **Resolution**: Automated remediation when possible
5. **Post-Mortem**: Automated incident documentation

Esta infraestrutura técnica garante que a MoreFocus possa operar de forma completamente automatizada, escalável e segura, suportando o crescimento para R$ 100.000/mês com apenas um funcionário, mantendo alta disponibilidade e compliance em todos os mercados globais.

