# Файл переменных: variables.tf

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Целевой регион AWS для развертывания Sterling Checkout (NA/EU routing)"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Мастер-пароль администратора базы данных (передается через переменные окружения)"
}
