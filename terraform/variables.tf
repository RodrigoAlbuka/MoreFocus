# MoreFocus - Terraform Variables (UPPER_CASE Standardized)

variable "AWS_REGION" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ENVIRONMENT" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "PROJECT_NAME" {
  description = "Project name for resource naming"
  type        = string
  default     = "morefocus"
}

variable "INSTANCE_TYPE" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"  # Free tier eligible
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium",
      "t2.micro", "t2.small", "t2.medium"
    ], var.INSTANCE_TYPE)
    error_message = "Instance type must be a valid EC2 type."
  }
}

variable "EBS_VOLUME_SIZE" {
  description = "Size of the EBS root volume in GB"
  type        = number
  default     = 20  # Free tier: up to 30GB
  
  validation {
    condition     = var.EBS_VOLUME_SIZE >= 8 && var.EBS_VOLUME_SIZE <= 100
    error_message = "EBS volume size must be between 8 and 100 GB."
  }
}

variable "SSH_PUBLIC_KEY" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.SSH_PUBLIC_KEY) > 0
    error_message = "SSH public key is required."
  }
}

variable "USE_RDS" {
  description = "Whether to use RDS PostgreSQL instead of SQLite"
  type        = bool
  default     = false  # SQLite para free tier
}

variable "USE_ELASTIC_IP" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = false  # Evitar custos extras
}

# Database variables
variable "DB_NAME" {
  description = "Database name"
  type        = string
  default     = "morefocus"
}

variable "DB_USER" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "DB_PASSWORD" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "ChangeThisPassword123!"
  
  validation {
    condition     = length(var.DB_PASSWORD) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "DB_HOST" {
  description = "Database host (for external databases like Supabase)"
  type        = string
  default     = "db.czlelqdsypwtwfmasvik.supabase.co"
}

variable "DB_PORT" {
  description = "Database port"
  type        = number
  default     = 5432
}

# n8n variables
variable "N8N_USER" {
  description = "n8n admin username"
  type        = string
  default     = "admin"
}

variable "N8N_PASSWORD" {
  description = "n8n admin password"
  type        = string
  sensitive   = true
  default     = "ChangeThisPassword123!"
  
  validation {
    condition     = length(var.N8N_PASSWORD) >= 8
    error_message = "n8n password must be at least 8 characters long."
  }
}

# Email configuration
variable "MAILGUN_API_KEY" {
  description = "Mailgun API key for email sending"
  type        = string
  default     = ""
  sensitive   = true
}

variable "MAILGUN_DOMAIN" {
  description = "Mailgun domain for email sending"
  type        = string
  default     = ""
}

# HubSpot integration
variable "HUBSPOT_ACCESS_TOKEN" {
  description = "HubSpot access token for CRM integration"
  type        = string
  default     = ""
  sensitive   = true
}

# Google Analytics
variable "GA_MEASUREMENT_ID" {
  description = "Google Analytics Measurement ID"
  type        = string
  default     = ""
}

variable "GA_API_SECRET" {
  description = "Google Analytics API Secret"
  type        = string
  default     = ""
  sensitive   = true
}

# Domain configuration
variable "DOMAIN_NAME" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "CREATE_ROUTE53_RECORDS" {
  description = "Whether to create Route53 DNS records"
  type        = bool
  default     = false
}

# SSL/TLS
variable "USE_SSL" {
  description = "Whether to configure SSL/TLS with Let's Encrypt"
  type        = bool
  default     = true
}

# Monitoring
variable "ENABLE_CLOUDWATCH_MONITORING" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false  # Evitar custos extras no free tier
}

# Backup configuration
variable "BACKUP_RETENTION_DAYS" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Scaling configuration
variable "ENABLE_AUTO_SCALING" {
  description = "Enable auto scaling (not recommended for free tier)"
  type        = bool
  default     = false
}

variable "MIN_INSTANCES" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
}

variable "MAX_INSTANCES" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 1
}

# Security
variable "ALLOWED_SSH_CIDRS" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restringir em produção
}

variable "ALLOWED_HTTP_CIDRS" {
  description = "CIDR blocks allowed for HTTP/HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Cost optimization
variable "ENABLE_SPOT_INSTANCES" {
  description = "Use spot instances for cost optimization (not recommended for production)"
  type        = bool
  default     = false
}

variable "SPOT_PRICE" {
  description = "Maximum spot price per hour"
  type        = string
  default     = "0.01"
}

# Tags
variable "ADDITIONAL_TAGS" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Feature flags
variable "ENABLE_REDIS" {
  description = "Enable Redis for caching (additional cost)"
  type        = bool
  default     = false
}

variable "ENABLE_ELASTICSEARCH" {
  description = "Enable Elasticsearch for logging (additional cost)"
  type        = bool
  default     = false
}

variable "ENABLE_VPC" {
  description = "Create custom VPC instead of using default"
  type        = bool
  default     = false  # Usar VPC padrão para simplicidade
}

# Supabase specific variables
variable "SUPABASE_HOST" {
  description = "Supabase database host"
  type        = string
  default     = "db.czlelqdsypwtwfmasvik.supabase.co"
}

variable "SUPABASE_PASSWORD" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
  default     = "h88b2wQPK2q-ry+"
}

variable "SUPABASE_SSL" {
  description = "Enable SSL for Supabase connection"
  type        = bool
  default     = true
}

