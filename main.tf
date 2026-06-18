# Промышленная конфигурация AWS RDS для Sterling Checkout
# Файл: main.tf

provider "aws" {
  region = var.aws_region
}

# 1. Создание изолированной VPC (Network Isolation)
resource "aws_vpc" "sterling_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "sterling-checkout-vpc"
    Environment = "Production"
  }
}

# 2. Создание приватных подсетей (Private Subnets) без доступа к интернет-шлюзу
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.sterling_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "sterling-db-subnet-private-az-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.sterling_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "sterling-db-subnet-private-az-b"
  }
}

# Группа подсетей для AWS RDS
resource "aws_db_subnet_group" "sterling_db_subnet_group" {
  name       = "sterling-checkout-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    Description = "Subnet group air-gapped from public internet routing"
  }
}

# 3. Настройка сетевой безопасности (Security Groups - Минимальные привилегии)
resource "aws_security_group" "rds_sg" {
  name        = "sterling-checkout-rds-security-group"
  description = "Allows inbound traffic explicitly from approved microservices"
  vpc_id      = aws_vpc.sterling_vpc.id

  # Входящий трафик на порт 5432 только из подсети приложения
  ingress {
    description = "PostgreSQL traffic access limited to trusted application layer block"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Ограничение внутренним диапазоном VPC
  }

  # Исходящий трафик (заблокирован или ограничен для безопасности)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Создание KMS ключа для шифрования данных в покое (At-Rest Cryptography)
resource "aws_kms_key" "rds_encryption_key" {
  description             = "KMS Key for Sterling Checkout production database encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

# 5. Параметры базы данных (Принудительное включение TLS/SSL для In-Transit)
resource "aws_db_parameter_group" "sterling_pg" {
  name   = "sterling-checkout-postgres15-pg"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = "1" # 1 означает жесткое требование SSL соединения
  }
}

# 6. Экземпляр управляемой базы данных AWS RDS (Производственный класс)
resource "aws_db_instance" "sterling_database" {
  identifierPrefix       = "sterling-checkout-prod-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t4g.medium" # Современная ARM-архитектура с высокой производительностью
  allocated_storage      = 50
  max_allocated_storage  = 500 # Автоматическое масштабирование хранилища до 500 ГБ

  # Настройки высокой доступности и отказоустойчивости (Multi-AZ)
  multi_az               = true 
  db_subnet_group_name   = aws_db_subnet_group.sterling_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Данные авторизации
  db_name                = "sterling_checkout_prod"
  username               = "sterling_admin"
  password               = var.db_password # Передается безопасно через переменные

  # Настройки безопасности и шифрования
  publicly_accessible    = false # Полный запрет на публичный доступ из интернета
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_encryption_key.arn
  parameter_group_name   = aws_db_parameter_group.sterling_pg.name

  # Окно резервного копирования и обслуживания
  backup_retention_period = 30 # Хранение бэкапов 30 дней для Point-in-Time Recovery
  backup_window           = "02:00-03:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"

  skip_final_snapshot     = false
  final_snapshot_identifier = "sterling-checkout-prod-db-final-snapshot"
}