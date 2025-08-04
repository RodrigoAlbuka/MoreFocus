# MoreFocus - Terraform Outputs

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.morefocus.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.morefocus.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.morefocus.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.morefocus.public_dns
}

output "elastic_ip" {
  description = "Elastic IP address (if enabled)"
  value       = var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : null
}

output "n8n_url" {
  description = "URL to access n8n interface"
  value       = "http://${var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/"
}

output "n8n_credentials" {
  description = "n8n login credentials"
  value = {
    username = var.n8n_user
    password = var.n8n_password
  }
  sensitive = true
}

output "webhook_endpoints" {
  description = "Webhook endpoints for the agents"
  value = {
    apq = "http://${var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/prospeccao"
    ane = "http://${var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/nutricao"
    avc = "http://${var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}:5678/webhook/vendas"
  }
}

output "database_endpoint" {
  description = "Database endpoint (if RDS is used)"
  value       = var.use_rds ? aws_db_instance.morefocus[0].endpoint : "SQLite (local)"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for backups"
  value       = aws_s3_bucket.morefocus.bucket
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.morefocus_ec2.id
}

output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.morefocus.key_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.morefocus_ec2.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.morefocus.name
}

# SSH connection command
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/morefocus-key.pem ubuntu@${var.use_elastic_ip ? aws_eip.morefocus[0].public_ip : aws_instance.morefocus.public_ip}"
}

# Status and monitoring
output "instance_status" {
  description = "Instance status information"
  value = {
    instance_state = aws_instance.morefocus.instance_state
    availability_zone = aws_instance.morefocus.availability_zone
    instance_type = aws_instance.morefocus.instance_type
    ami_id = aws_instance.morefocus.ami
  }
}

# Cost estimation
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    ec2_instance = var.instance_type == "t3.micro" ? "Free Tier (750 hours/month)" : "~$8-20/month"
    ebs_storage = var.ebs_volume_size <= 30 ? "Free Tier (30GB)" : "~$0.10/GB/month"
    rds_database = var.use_rds ? (var.use_rds ? "Free Tier (750 hours/month)" : "N/A") : "Free (SQLite)"
    elastic_ip = var.use_elastic_ip ? "$3.65/month" : "Free (dynamic IP)"
    s3_storage = "~$0.023/GB/month"
    data_transfer = "Free Tier (1GB/month out)"
    total_estimate = var.instance_type == "t3.micro" && !var.use_elastic_ip && !var.use_rds ? "~$5-10/month" : "~$15-30/month"
  }
}

# Next steps
output "next_steps" {
  description = "Next steps after deployment"
  value = [
    "1. Wait 5-10 minutes for instance initialization",
    "2. Access n8n at the provided URL",
    "3. Login with the provided credentials",
    "4. Import workflow JSON files",
    "5. Activate workflows in n8n interface",
    "6. Configure external integrations",
    "7. Test webhook endpoints",
    "8. Set up domain and SSL (optional)"
  ]
}

# Troubleshooting
output "troubleshooting" {
  description = "Troubleshooting information"
  value = {
    logs_location = "/var/log/user-data.log"
    status_file = "/opt/morefocus/status.json"
    docker_logs = "docker logs morefocus-n8n"
    service_restart = "cd /opt/morefocus && docker-compose restart"
    backup_script = "/opt/morefocus/scripts/backup.sh"
  }
}

