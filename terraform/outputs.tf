output "lambda_function_name" {
  description = "Nome da função Lambda criada"
  value       = aws_lambda_function.auth_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN da função Lambda"
  value       = aws_lambda_function.auth_lambda.arn
}

output "lambda_function_url" {
  description = "URL pública para invocar a Lambda"
  value       = aws_lambda_function_url.auth_url.function_url
}

output "lambda_role_arn" {
  description = "ARN da IAM Role da Lambda"
  value       = aws_iam_role.lambda_role.arn
}
