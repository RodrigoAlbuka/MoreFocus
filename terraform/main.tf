# MoreFocus - Infraestrutura AWS com Terraform
# Versão Free Tier Otimizada

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
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "MoreFocus"
      Environment = var.environment
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
  key_name   = "${var.project_name}-keypair"
  public_key = var.ssh_public_key
}

# Security Group para EC2
resource "aws_security_group" "morefocus_ec2" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group for MoreFocus EC2 instance"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # n8n
  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name = "${var.project_name}-ec2-sg"
  }
}

# Security Group para RDS (se usar PostgreSQL)
resource "aws_security_group" "morefocus_rds" {
  count = var.use_rds ? 1 : 0
  
  name_prefix = "${var.project_name}-rds-"
  description = "Security group for MoreFocus RDS instance"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.morefocus_ec2.id]
    description     = "PostgreSQL access from EC2"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# EC2 Instance
resource "aws_instance" "morefocus" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.morefocus.key_name
  vpc_security_group_ids = [aws_security_group.morefocus_ec2.id]
  
  # User data para setup inicial
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host     = var.use_rds ? aws_db_instance.morefocus[0].endpoint : "localhost"
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    n8n_user    = var.n8n_user
    n8n_password = var.n8n_password
    use_rds     = var.use_rds
  }))

  # EBS otimizado para free tier
  root_block_device {
    volume_type = "gp3"
    volume_size = var.ebs_volume_size
    encrypted   = true
    
    tags = {
      Name = "${var.project_name}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-main"
    Type = "Application Server"
  }
}

# RDS Instance (opcional - apenas se não usar SQLite)
resource "aws_db_subnet_group" "morefocus" {
  count = var.use_rds ? 1 : 0
  
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_db_instance" "morefocus" {
  count = var.use_rds ? 1 : 0
  
  identifier = "${var.project_name}-db"
  
  # Free tier eligible
  engine         = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"
  
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type         = "gp2"
  storage_encrypted    = true
  
  db_name  = var.db_name
  username = var.db_user
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.morefocus_rds[0].id]
  db_subnet_group_name   = aws_db_subnet_group.morefocus[0].name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  tags = {
    Name = "${var.project_name}-database"
  }
}

# S3 Bucket para backups e assets
resource "aws_s3_bucket" "morefocus" {
  bucket = "${var.project_name}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name = "${var.project_name}-storage"
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
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7
  
  tags = {
    Name = "${var.project_name}-logs"
  }
}

# Elastic IP (opcional)
resource "aws_eip" "morefocus" {
  count = var.use_elastic_ip ? 1 : 0
  
  instance = aws_instance.morefocus.id
  domain   = "vpc"
  
  tags = {
    Name = "${var.project_name}-eip"
  }
}

# IAM Role para EC2
resource "aws_iam_role" "morefocus_ec2" {
  name = "${var.project_name}-ec2-role"

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
  name = "${var.project_name}-ec2-policy"
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
        Resource = "${aws_cloudwatch_log_group.morefocus.arn}:*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "morefocus_ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.morefocus_ec2.name
}

