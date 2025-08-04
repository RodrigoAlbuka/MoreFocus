# MoreFocus - Terraform Outputs
# Variáveis padronizadas em UPPER_CASE

output "INSTANCE_ID" {
  description = "ID of the EC2 instance"
  value       = aws_instance.morefocus.id
}

output "INSTANCE_PUBLIC_IP" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.morefocus.public_ip
}

output "INSTANCE_PRIVATE_IP" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.morefocus.private_ip
}

output "INSTANCE_PUBLIC_DNS" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.morefocus.public_dns
}

output "ELASTIC_IP" {
  description = "Elastic IP address (if enabled)"
  value       = var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : null
}

output "N8N_URL" {
  description = "URL to access n8n interface"
  value       = "http://${var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/"
}

output "N8N_CREDENTIALS" {
  description = "n8n login credentials"
  value = {
    username = var.N8N_USER
    password = var.N8N_PASSWORD
  }
  sensitive = true
}

output "WEBHOOK_ENDPOINTS" {
  description = "Webhook endpoints for the agents"
  value = {
    apq = "http://${var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/prospeccao"
    ane = "http://${var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/nutricao"
    avc = "http://${var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/vendas"
  }
}

output "DATABASE_INFO" {
  description = "Database connection information"
  value = {
    type     = "PostgreSQL"
    provider = "Supabase"
    host     = var.SUPABASE_HOST
    database = var.DB_NAME
    ssl      = var.SUPABASE_SSL
  }
}

output "S3_BUCKET_NAME" {
  description = "Name of the S3 bucket for backups"
  value       = aws_s3_bucket.morefocus.bucket
}

output "SECURITY_GROUP_ID" {
  description = "ID of the security group"
  value       = aws_security_group.morefocus_ec2.id
}

output "KEY_PAIR_NAME" {
  description = "Name of the key pair"
  value       = aws_key_pair.morefocus.key_name
}

output "IAM_ROLE_ARN" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.morefocus_ec2.arn
}

output "CLOUDWATCH_LOG_GROUP" {
  description = "CloudWatch log group name"
  value       = var.ENABLE_CLOUDWATCH_MONITORING ? aws_cloudwatch_log_group.morefocus[0].name : "Disabled"
}

# SSH connection command
output "SSH_COMMAND" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.PROJECT_NAME}-key.pem ubuntu@${var.USE_ELASTIC_IP ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}"
}

# Status and monitoring
output "INSTANCE_STATUS" {
  description = "Instance status information"
  value = {
    instance_state    = aws_instance.morefocus.instance_state
    availability_zone = aws_instance.morefocus.availability_zone
    instance_type     = aws_instance.morefocus.instance_type
    ami_id           = aws_instance.morefocus.ami
  }
}

# Cost estimation
output "ESTIMATED_MONTHLY_COST" {
  description = "Estimated monthly cost breakdown"
  value = {
    ec2_instance  = var.INSTANCE_TYPE == "t3.micro" ? "Free Tier (750 hours/month)" : "~$8-20/month"
    ebs_storage   = var.EBS_VOLUME_SIZE <= 30 ? "Free Tier (30GB)" : "~$0.10/GB/month"
    elastic_ip    = var.USE_ELASTIC_IP ? "$3.65/month" : "Free (dynamic IP)"
    s3_storage    = "~$0.023/GB/month"
    data_transfer = "Free Tier (1GB/month out)"
    cloudwatch    = var.ENABLE_CLOUDWATCH_MONITORING ? "~$0.50/month" : "Free"
    total_estimate = var.INSTANCE_TYPE == "t3.micro" && !var.USE_ELASTIC_IP && !var.ENABLE_CLOUDWATCH_MONITORING ? "~$2-5/month" : "~$10-25/month"
  }
}

# Next steps
output "NEXT_STEPS" {
  description = "Next steps after deployment"
  value = [
    "1. Wait 5-10 minutes for instance initialization",
    "2. Access n8n at the provided URL",
    "3. Login with the provided credentials",
    "4. Import workflow JSON files from /workflows/ directory",
    "5. Activate workflows in n8n interface",
    "6. Configure external integrations (email, CRM)",
    "7. Test webhook endpoints",
    "8. Set up domain and SSL (optional)"
  ]
}

# Troubleshooting
output "TROUBLESHOOTING" {
  description = "Troubleshooting information"
  value = {
    logs_location    = "/var/log/user-data.log"
    status_file      = "/opt/${var.PROJECT_NAME}/status.json"
    docker_logs      = "docker logs morefocus-n8n"
    service_restart  = "cd /opt/${var.PROJECT_NAME} && docker-compose restart"
    backup_script    = "/opt/${var.PROJECT_NAME}/scripts/backup.sh"
    health_check     = "/opt/${var.PROJECT_NAME}/scripts/health_check.sh"
  }
}

# Project information
output "PROJECT_INFO" {
  description = "Project configuration summary"
  value = {
    project_name = var.PROJECT_NAME
    environment  = var.ENVIRONMENT
    aws_region   = var.AWS_REGION
    deployment_date = timestamp()
    terraform_version = ">=1.0"
    database_provider = "Supabase"
    ssl_enabled = var.SUPABASE_SSL
  }
}

