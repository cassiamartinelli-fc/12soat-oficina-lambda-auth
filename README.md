# Oficina Mecânica — Lambda de Autenticação

Function serverless para autenticação de clientes via CPF, retornando token JWT.

## 🎯 Propósito

Autenticar clientes através do CPF, validando no Neon PostgreSQL e gerando token JWT com validade de 24h para acesso às APIs protegidas.

## 🛠️ Tecnologias

- **AWS Lambda** — Execução serverless (Node.js 20)
- **Neon PostgreSQL** — Banco de dados gerenciado
- **Terraform** — Infraestrutura como código
- **GitHub Actions** — CI/CD automático
- **JWT** — Geração de tokens de autenticação

## 📁 Estrutura

```
src/index.js      # Handler: valida CPF + gera JWT
terraform/        # AWS Lambda + Function URL + IAM
.github/workflows # CI/CD
```

## 🚀 Setup

A Lambda de autenticação é deployada via GitHub Actions ou Terraform.

**Para obter URL da Lambda:**

Execute `terraform output lambda_function_url` no diretório `terraform/` ou verifique os logs do último workflow de deploy.

⚠️ **Quando a Lambda não está disponível:**
- Lambda nunca foi deployada (primeira execução do projeto)
- Lambda foi deletada com `terraform destroy`
- Secrets ausentes ou incorretos
- Permissões IAM incorretas

**Para deployar:**

### Deploy Automático (Recomendado)

Push na branch `main` → GitHub Actions faz deploy automaticamente.

**Workflow:** `.github/workflows/cd.yml`

### Deploy Manual

```bash
# 1. Criar bucket S3 para Terraform state (executar UMA VEZ)
aws s3api create-bucket --bucket 12soat-terraform-state-lambda --region us-east-1

# 2. Configurar variáveis
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com NEON_DATABASE_URL e JWT_SECRET

# 3. Deploy
terraform init
terraform apply

# 4. Obter URL da Lambda
terraform output lambda_function_url
```

## 🔐 CI/CD — Secrets e permissões

✅ **Todos os secrets já estão devidamente configurados neste repositório.**

**Secrets necessários (Settings → Secrets → Actions):**
- `NEON_DATABASE_URL` — Connection string PostgreSQL
- `JWT_SECRET` — Secret para geração de tokens
- `AWS_ACCESS_KEY_ID` — AWS Access Key
- `AWS_SECRET_ACCESS_KEY` — AWS Secret Key

**Para replicar em sua própria conta:** Ver `terraform/terraform.tfvars.example` para variáveis necessárias.

## 🧪 Validação

```bash
# 1. Obter URL da Lambda
cd terraform
terraform output -raw lambda_function_url

# 2. Testar autenticação
curl -X POST "<URL_OBTIDA>" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}'
```

**Respostas esperadas:**
- **200 OK**: `{"token": "eyJ...", "cliente": {"id": "...", "nome": "..."}}`
- **404 Not Found**: `{"error": "Cliente não encontrado"}`
- **400 Bad Request**: `{"error": "CPF inválido"}`

## 📊 Arquitetura

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ POST {"cpf":"12345678900"}
       ▼
┌─────────────────────────┐
│  Lambda Function URL    │
│  (CORS habilitado)      │
└──────────┬──────────────┘
           │
           ▼
    ┌──────────────┐
    │ AWS Lambda   │
    │ Node.js 20   │
    └──────┬───────┘
           │ 1. Valida CPF (formato)
           │ 2. Consulta Neon PostgreSQL
           │ 3. Gera JWT (24h)
           ▼
    ┌──────────────────┐
    │ Neon PostgreSQL  │
    │ (tabela clientes)│
    └──────────────────┘
```


## 🔗 Repositórios Relacionados

- [12soat-oficina-app](https://github.com/cassiamartinelli-fc/12soat-oficina-app)
- [12soat-oficina-infra-database](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-database)
- [12soat-oficina-infra-k8s](https://github.com/cassiamartinelli-fc/12soat-oficina-infra-k8s)

## 📄 Licença

MIT - Tech Challenge 12SOAT Fase 3
