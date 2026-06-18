# Production AWS RDS Infrastructure for Sterling Checkout
# File: main.tf

provider "aws" {
  region = var.aws_region
}

# =========================================================================
# NETWORK CONTEXT
# =========================================================================

resource "aws_vpc" "sterling_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "sterling-prod-vpc"
    Environment = "Production"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.sterling_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "sterling-subnet-db-private-a" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.sterling_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  tags              = { Name = "sterling-subnet-db-private-b" }
}

resource "aws_db_subnet_group" "sterling_db_group" {
  name       = "sterling-prod-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

# =========================================================================
# FINE-GRAINED SECURITY GROUPS (Detailed Access Control)
# =========================================================================

# Simulated Security Group for Application Microservices
resource "aws_security_group" "app_tier_sg" {
  name        = "sterling-prod-app-tier-sg"
  description = "Security group for trusted checkout/order microservices instances"
  vpc_id      = aws_vpc.sterling_vpc.id
}

# Simulated Security Group for Dedicated Administrative Paths (Bastion Host)
resource "aws_security_group" "bastion_sg" {
  name        = "sterling-prod-bastion-admin-sg"
  description = "Security group for secure MFA-enabled administrative Bastion host"
  vpc_id      = aws_vpc.sterling_vpc.id
}

# Target RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "sterling-prod-rds-security-group"
  description = "Airtight ingress control for transactional database tier"
  vpc_id      = aws_vpc.sterling_vpc.id

  # Rule 1: Access from App Tier only
  ingress {
    description     = "Allow state mutations explicitly from approved application microservices"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier_sg.id] 
  }

  # Rule 2: Access from Bastion Host only (Admin Path)
  ingress {
    description     = "Allow schema updates and DBA access via dedicated administrative bastion path"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================================================================
# CRYPTOGRAPHY & COMPLIANCE GUARDRAILS
# =========================================================================

resource "aws_kms_key" "rds_key" {
  description             = "KMS Key for Sterling Checkout AES-256 cluster storage encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_db_parameter_group" "sterling_pg" {
  name   = "sterling-prod-postgres15-parameter-group"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = "1" # Hard enforcement of TLS/SSL connections
  }
}

# =========================================================================
# MANAGED DATABASE INSTANCE SPECIFICATION
# =========================================================================

resource "aws_db_instance" "sterling_db" {
  identifier        = "sterling-checkout-production-db"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t4g.medium" # ARM-based performant and cost-optimized node
  allocated_storage = 50
  max_allocated_storage = 500 # Transparent elastic auto-scaling enabled

  multi_az               = true # High availability synchronous cross-AZ replication
  db_subnet_group_name   = aws_db_subnet_group.sterling_db_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_name  = "sterling_checkout_prod"
  username = "sterling_root_admin"
  password = var.db_password

  publicly_accessible  = false # Explicit network air-gapping
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds_key.arn
  parameter_group_name = aws_db_parameter_group.sterling_pg.name

  backup_retention_period = 30
  backup_window           = "02:00-03:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"
  skip_final_snapshot     = false
  final_snapshot_identifier = "sterling-checkout-prod-db-final-snap"
}
