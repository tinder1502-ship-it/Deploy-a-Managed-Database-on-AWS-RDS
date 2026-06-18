# File: variables.tf

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "Primary target AWS Region for Sterling Checkout deployment"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Master administrative password passed via pipeline environment"
}
