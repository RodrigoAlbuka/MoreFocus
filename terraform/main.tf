# MoreFocus - Infraestrutura AWS com Terraform
# Versão Free Tier Otimizada com Supabase PostgreSQL
# Variáveis padronizadas em UPPER_CASE

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider AWS
provider "aws" {
  region = var.AWS_REGION
  
  default_tags {
    tags = {
      Project     = "MoreFocus"
      Environment = var.ENVIRONMENT
      ManagedBy   = "Terraform"
      Owner       = "MoreFocus Team"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key Pair para acesso SSH
resource "aws_key_pair" "morefocus" {
  key_name   = "${var.PROJECT_NAME}-keypair"
  public_key = var.SSH_PUBLIC_KEY
}

# Security Group para EC2
resource "aws_security_group" "morefocus_ec2" {
  name_prefix = "${var.PROJECT_NAME}-ec2-"
  description = "Security group for MoreFocus EC2 instance"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ALLOWED_SSH_CIDRS
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ALLOWED_HTTP_CIDRS
    description = "HTTP access"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ALLOWED_HTTP_CIDRS
    description = "HTTPS access"
  }

  # n8n
  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = var.ALLOWED_HTTP_CIDRS
    description = "n8n interface"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.PROJECT_NAME}-ec2-sg"
  }
}

# EC2 Instance
resource "aws_instance" "morefocus" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.INSTANCE_TYPE
  key_name              = aws_key_pair.morefocus.key_name
  vpc_security_group_ids = [aws_security_group.morefocus_ec2.id]
  
  # User data com variáveis padronizadas
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    N8N_USER           = var.N8N_USER
    N8N_PASSWORD       = var.N8N_PASSWORD
    SUPABASE_HOST      = var.SUPABASE_HOST
    SUPABASE_PASSWORD  = var.SUPABASE_PASSWORD
    DB_NAME            = var.DB_NAME
    DB_USER            = var.DB_USER
    PROJECT_NAME       = var.PROJECT_NAME
  }))

  # EBS otimizado para free tier
  root_block_device {
    volume_type = "gp3"
    volume_size = var.EBS_VOLUME_SIZE
    encrypted   = true
    
    tags = {
      Name = "${var.PROJECT_NAME}-root-volume"
    }
  }

  tags = {
    Name = "${var.PROJECT_NAME}-main"
    Type = "Application Server"
  }
}

# Elastic IP (opcional)
resource "aws_eip" "morefocus" {
  count = var.USE_ELASTIC_IP ? 1 : 0
  
  instance = aws_instance.morefocus.id
  domain   = "vpc"
  
  tags = {
    Name = "${var.PROJECT_NAME}-eip"
  }
}

# S3 Bucket para backups e assets
resource "aws_s3_bucket" "morefocus" {
  bucket = "${var.PROJECT_NAME}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.PROJECT_NAME}-storage"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "morefocus" {
  bucket = aws_s3_bucket.morefocus.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "morefocus" {
  bucket = aws_s3_bucket.morefocus.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "morefocus" {
  bucket = aws_s3_bucket.morefocus.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "morefocus" {
  count = var.ENABLE_CLOUDWATCH_MONITORING ? 1 : 0
  
  name              = "/aws/ec2/${var.PROJECT_NAME}"
  retention_in_days = var.BACKUP_RETENTION_DAYS
  
  tags = {
    Name = "${var.PROJECT_NAME}-logs"
  }
}

# IAM Role para EC2
resource "aws_iam_role" "morefocus_ec2" {
  name = "${var.PROJECT_NAME}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "morefocus_ec2" {
  name = "${var.PROJECT_NAME}-ec2-policy"
  role = aws_iam_role.morefocus_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.morefocus.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.morefocus.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = var.ENABLE_CLOUDWATCH_MONITORING ? "${aws_cloudwatch_log_group.morefocus[0].arn}:*" : ""
      }
    ]
  })
}

resource "aws_iam_instance_profile" "morefocus_ec2" {
  name = "${var.PROJECT_NAME}-ec2-profile"
  role = aws_iam_role.morefocus_ec2.name
}

