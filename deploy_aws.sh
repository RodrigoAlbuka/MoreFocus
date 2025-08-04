#!/bin/bash

# MoreFocus - Deploy Automatizado para AWS
# Este script automatiza todo o processo de deploy na AWS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "🚀 MoreFocus - Deploy Automatizado para AWS"
echo "=============================================="
echo ""

# Verificar pré-requisitos
log_info "Verificando pré-requisitos..."

# Verificar se está no diretório correto
if [ ! -f "terraform/main.tf" ]; then
    log_error "Execute este script no diretório raiz do projeto MoreFocus"
    exit 1
fi

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
    exit 1
fi

# Verificar Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform não encontrado. Instale: https://terraform.io/downloads"
    exit 1
fi

# Verificar credenciais AWS
log_info "Verificando credenciais AWS..."
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "Credenciais AWS não configuradas. Execute: aws configure"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
log_success "AWS Account: $AWS_ACCOUNT, Region: $AWS_REGION"

# Verificar se terraform.tfvars existe
if [ ! -f "terraform/terraform.tfvars" ]; then
    log_warning "Arquivo terraform.tfvars não encontrado"
    
    read -p "Deseja criar um arquivo terraform.tfvars básico? (y/n): " create_tfvars
    if [ "$create_tfvars" = "y" ]; then
        log_info "Criando terraform.tfvars..."
        
        # Gerar chave SSH se não existir
        if [ ! -f "$HOME/.ssh/morefocus-key" ]; then
            log_info "Gerando chave SSH..."
            ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/morefocus-key" -N ""
            log_success "Chave SSH criada: $HOME/.ssh/morefocus-key"
        fi
        
        # Criar arquivo terraform.tfvars básico
        cat > terraform/terraform.tfvars << EOF
# MoreFocus - Configuração Básica
aws_region = "$AWS_REGION"
project_name = "morefocus"
instance_type = "t3.micro"
ebs_volume_size = 20
use_rds = false
use_elastic_ip = false
ssh_public_key = "$(cat $HOME/.ssh/morefocus-key.pub)"
n8n_user = "admin"
n8n_password = "$(openssl rand -base64 12)"
db_password = "$(openssl rand -base64 12)"
EOF
        
        log_success "Arquivo terraform.tfvars criado com configuração básica"
        log_warning "Edite o arquivo se necessário: nano terraform/terraform.tfvars"
        
        read -p "Pressione Enter para continuar ou Ctrl+C para editar o arquivo..."
    else
        log_error "Crie o arquivo terraform.tfvars baseado no exemplo"
        log_info "cp terraform/terraform.tfvars.example terraform/terraform.tfvars"
        exit 1
    fi
fi

# Mostrar configuração
log_info "Configuração do deploy:"
echo "  - Região: $AWS_REGION"
echo "  - Conta AWS: $AWS_ACCOUNT"
echo "  - Projeto: $(grep 'project_name' terraform/terraform.tfvars | cut -d'"' -f2 || echo 'morefocus')"
echo "  - Instância: $(grep 'instance_type' terraform/terraform.tfvars | cut -d'"' -f2 || echo 't3.micro')"
echo "  - RDS: $(grep 'use_rds' terraform/terraform.tfvars | cut -d'=' -f2 | xargs || echo 'false')"
echo ""

# Confirmação
read -p "Continuar com o deploy? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    log_info "Deploy cancelado pelo usuário"
    exit 0
fi

# Navegar para diretório terraform
cd terraform

# Inicializar Terraform
log_info "Inicializando Terraform..."
terraform init

# Validar configuração
log_info "Validando configuração..."
terraform validate

# Planejar deploy
log_info "Criando plano de execução..."
terraform plan -out=tfplan

# Mostrar resumo do plano
log_info "Resumo do plano:"
terraform show -json tfplan | jq -r '.planned_values.root_module.resources[] | select(.type == "aws_instance") | "  - EC2: \(.values.instance_type) (\(.values.ami))"'

# Confirmação final
echo ""
log_warning "ATENÇÃO: Este deploy criará recursos na AWS que podem gerar custos"
read -p "Confirma o deploy? Digite 'yes' para continuar: " final_confirm
if [ "$final_confirm" != "yes" ]; then
    log_info "Deploy cancelado pelo usuário"
    rm -f tfplan
    exit 0
fi

# Executar deploy
log_info "Executando deploy..."
terraform apply tfplan

# Verificar se deploy foi bem-sucedido
if [ $? -eq 0 ]; then
    log_success "Deploy concluído com sucesso!"
    
    # Obter outputs
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    N8N_URL=$(terraform output -raw n8n_url)
    SSH_COMMAND=$(terraform output -raw ssh_command)
    
    echo ""
    echo "🎉 MoreFocus implantado com sucesso!"
    echo "=================================="
    echo ""
    echo "📋 Informações de acesso:"
    echo "  🌐 n8n Interface: $N8N_URL"
    echo "  👤 Usuário: $(terraform output -json n8n_credentials | jq -r '.username')"
    echo "  🔑 Senha: $(terraform output -json n8n_credentials | jq -r '.password')"
    echo ""
    echo "🔗 Webhooks:"
    terraform output -json webhook_endpoints | jq -r 'to_entries[] | "  \(.key | ascii_upcase): \(.value)"'
    echo ""
    echo "🖥️  SSH: $SSH_COMMAND"
    echo ""
    
    # Aguardar inicialização
    log_info "Aguardando inicialização dos serviços (pode levar 5-10 minutos)..."
    
    # Verificar se n8n está respondendo
    for i in {1..30}; do
        if curl -s -f "$N8N_URL" > /dev/null 2>&1; then
            log_success "n8n está respondendo!"
            break
        fi
        
        if [ $i -eq 30 ]; then
            log_warning "n8n ainda não está respondendo. Verifique os logs:"
            echo "  ssh -i ~/.ssh/morefocus-key ubuntu@$INSTANCE_IP"
            echo "  tail -f /var/log/user-data.log"
        else
            echo -n "."
            sleep 20
        fi
    done
    
    echo ""
    log_info "Próximos passos:"
    echo "  1. Acesse $N8N_URL"
    echo "  2. Faça login com as credenciais acima"
    echo "  3. Importe os workflows JSON:"
    echo "     - workflows/APQ_Agente_Prospeccao.json"
    echo "     - workflows/ANE_Agente_Nutricao.json"
    echo "     - workflows/AVC_Agente_Vendas.json"
    echo "  4. Ative os workflows na interface"
    echo "  5. Configure integrações externas (email, CRM)"
    echo "  6. Teste os webhooks"
    echo ""
    
    # Salvar informações em arquivo
    cat > ../deploy_info.txt << EOF
MoreFocus - Informações do Deploy
================================

Data do Deploy: $(date)
Região AWS: $AWS_REGION
Conta AWS: $AWS_ACCOUNT

Acesso:
- n8n Interface: $N8N_URL
- Usuário: $(terraform output -json n8n_credentials | jq -r '.username')
- Senha: $(terraform output -json n8n_credentials | jq -r '.password')

SSH:
$SSH_COMMAND

Webhooks:
$(terraform output -json webhook_endpoints | jq -r 'to_entries[] | "- \(.key | ascii_upcase): \(.value)"')

Recursos Criados:
- EC2 Instance: $(terraform output -raw instance_id)
- Security Group: $(terraform output -raw security_group_id)
- S3 Bucket: $(terraform output -raw s3_bucket_name)
- Key Pair: $(terraform output -raw key_pair_name)

Custos Estimados:
$(terraform output -json estimated_monthly_cost | jq -r 'to_entries[] | "- \(.key): \(.value)"')

Troubleshooting:
- Logs: tail -f /var/log/user-data.log
- Status: cat /opt/morefocus/status.json
- Restart: cd /opt/morefocus && docker-compose restart
EOF
    
    log_success "Informações salvas em: deploy_info.txt"
    
else
    log_error "Deploy falhou! Verifique os logs acima"
    exit 1
fi

# Limpeza
rm -f tfplan

echo ""
log_success "Deploy concluído! 🎉"
echo ""
echo "💡 Dicas:"
echo "  - Mantenha o arquivo terraform.tfvars seguro (contém senhas)"
echo "  - Faça backup regular: terraform output > backup.txt"
echo "  - Para destruir: terraform destroy"
echo "  - Para atualizar: terraform apply"
echo ""
echo "📞 Suporte: https://github.com/morefocus/docs"

