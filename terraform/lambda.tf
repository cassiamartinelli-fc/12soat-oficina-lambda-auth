# ========================================
# IAM Role para Lambda
# ========================================

resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Anexar política básica de execução da Lambda
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política para permitir acesso à VPC (se necessário no futuro)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ========================================
# Empacotar código da Lambda
# ========================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../"
  output_path = "${path.module}/lambda-auth.zip"

  excludes = [
    "terraform",
    ".terraform",
    ".git",
    ".github",
    "*.md",
    "*.sql",
    "test-local.js",
    ".env",
    ".env.example",
    ".gitignore",
    "LICENSE"
  ]
}

# ========================================
# Lambda Function
# ========================================

resource "aws_lambda_function" "auth_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "src/index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      NEON_DATABASE_URL = var.neon_database_url
      JWT_SECRET        = var.jwt_secret
    }
  }

  tags = {
    Name        = "Oficina Mecânica - Autenticação"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ========================================
# Lambda Function URL (acesso público HTTP)
# ========================================

resource "aws_lambda_function_url" "auth_url" {
  function_name      = aws_lambda_function.auth_lambda.function_name
  authorization_type = "NONE" # Acesso público

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
    max_age           = 86400
  }
}

# Permitir invocação pública via Function URL
resource "aws_lambda_permission" "allow_function_url" {
  statement_id  = "AllowPublicFunctionURLInvoke"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.auth_lambda.function_name
  principal     = "*"

  function_url_auth_type = "NONE"

  condition {
    test     = "StringEquals"
    variable = "aws:SourceArn"
    values   = [aws_lambda_function_url.auth_url.function_url]
  }
}
