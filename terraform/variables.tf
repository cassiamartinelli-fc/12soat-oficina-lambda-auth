variable "aws_region" {
  description = "AWS region for Lambda deployment"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Nome da função Lambda"
  type        = string
  default     = "oficina-mecanica-auth"
}

variable "neon_database_url" {
  description = "Connection string do Neon PostgreSQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Secret para geração de tokens JWT"
  type        = string
  sensitive   = true
}
