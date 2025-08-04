# MoreFocus - Terraform Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "morefocus"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium",
      "t2.micro", "t2.small", "t2.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 type."
  }
}

variable "ebs_volume_size" {
  description = "Size of the EBS root volume in GB"
  type        = number
  default     = 20  # Free tier: up to 30GB
  
  validation {
    condition     = var.ebs_volume_size >= 8 && var.ebs_volume_size <= 100
    error_message = "EBS volume size must be between 8 and 100 GB."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.ssh_public_key) > 0
    error_message = "SSH public key is required."
  }
}

variable "use_rds" {
  description = "Whether to use RDS PostgreSQL instead of SQLite"
  type        = bool
  default     = false  # SQLite para free tier
}

variable "use_elastic_ip" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = false  # Evitar custos extras
}

# Database variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "morefocus"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "ChangeThisPassword123!"
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# n8n variables
variable "n8n_user" {
  description = "n8n admin username"
  type        = string
  default     = "admin"
}

variable "n8n_password" {
  description = "n8n admin password"
  type        = string
  sensitive   = true
  default     = "ChangeThisPassword123!"
  
  validation {
    condition     = length(var.n8n_password) >= 8
    error_message = "n8n password must be at least 8 characters long."
  }
}

# Email configuration
variable "mailgun_api_key" {
  description = "Mailgun API key for email sending"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mailgun_domain" {
  description = "Mailgun domain for email sending"
  type        = string
  default     = ""
}

# HubSpot integration
variable "hubspot_access_token" {
  description = "HubSpot access token for CRM integration"
  type        = string
  default     = ""
  sensitive   = true
}

# Google Analytics
variable "ga_measurement_id" {
  description = "Google Analytics Measurement ID"
  type        = string
  default     = ""
}

variable "ga_api_secret" {
  description = "Google Analytics API Secret"
  type        = string
  default     = ""
  sensitive   = true
}

# Domain configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "create_route53_records" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = false
}

# SSL/TLS
variable "use_ssl" {
  description = "Whether to configure SSL/TLS with Let's Encrypt"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_cloudwatch_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false  # Evitar custos extras no free tier
}

# Backup configuration
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Scaling configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling (not recommended for free tier)"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 1
}

# Security
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restringir em produção
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Cost optimization
variable "enable_spot_instances" {
  description = "Use spot instances for cost optimization (not recommended for production)"
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "Maximum spot price per hour"
  type        = string
  default     = "0.01"
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Feature flags
variable "enable_redis" {
  description = "Enable Redis for caching (additional cost)"
  type        = bool
  default     = false
}

variable "enable_elasticsearch" {
  description = "Enable Elasticsearch for logging (additional cost)"
  type        = bool
  default     = false
}

variable "enable_vpc" {
  description = "Create custom VPC instead of using default"
  type        = bool
  default     = false  # Usar VPC padrão para simplicidade
}

