# 12SOAT - Oficina Mecânica - Lambda Auth

Function serverless para autenticação via CPF.

## Stack
- AWS Lambda (Node.js 20)
- Neon PostgreSQL
- JWT

## Estrutura
```
src/index.js         - Handler Lambda
terraform/           - Infraestrutura como código
.github/workflows/   - CI/CD
```

## Deploy
```bash
cd terraform
terraform init
terraform apply
```

## Secrets Necessários
- `NEON_DATABASE_URL`
- `JWT_SECRET`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
