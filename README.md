# Lambda de Autenticação - Oficina Mecânica

Function serverless para autenticação de clientes via CPF, consultando o banco Neon PostgreSQL e retornando token JWT.

---

## 🎯 Propósito

Autenticar clientes da oficina mecânica através do CPF, validando sua existência no banco de dados e gerando um token JWT válido por 24h para acesso às APIs protegidas.

---

## 🛠️ Tecnologias

- **AWS Lambda** - Execução serverless (Node.js 20)
- **Neon PostgreSQL** - Banco de dados gerenciado
- **Terraform** - Infraestrutura como código
- **GitHub Actions** - CI/CD automático
- **JWT** - Geração de tokens de autenticação

---

## 📁 Estrutura do Projeto

```
src/
  └── index.js              # Handler da Lambda (validação CPF + JWT)
terraform/
  ├── main.tf               # Provider AWS + S3 Backend
  ├── lambda.tf             # Lambda + IAM Role + Function URL
  ├── variables.tf          # Variáveis
  └── outputs.tf            # Outputs (URL da Lambda)
.github/workflows/
  ├── ci.yml                # Validação (PRs)
  └── deploy.yml            # Deploy automático (main)
```

### **Infraestrutura criada pelo Terraform:**
- AWS Lambda Function (`oficina-mecanica-auth`)
- IAM Role com permissões básicas
- Lambda Function URL (acesso público via HTTPS)
- Estado armazenado em S3 (`s3://12soat-terraform-state-lambda`)

---

## 🚀 Setup e Deploy

### **Pré-requisitos**

**Ferramentas locais:**
- AWS CLI configurado com credenciais válidas
- Terraform instalado

**Infraestrutura e dados:**
- **Banco Neon PostgreSQL** criado → [12soat-oficina-infra-database](https://github.com/<usuario>/12soat-oficina-infra-database)
- **Aplicação NestJS** rodada pelo menos uma vez → [12soat-oficina-app](https://github.com/<usuario>/12soat-oficina-app)
  - Isso garante que a tabela `clientes` existe no banco
- **Pelo menos um cliente cadastrado** via API
  - A Lambda consulta a tabela `clientes` para validar CPF

### **1. Criar Bucket S3 para Terraform State**

Execute **UMA ÚNICA VEZ** (se ainda não existir):

```bash
aws s3api create-bucket \
  --bucket 12soat-terraform-state-lambda \
  --region us-east-1
```

### **2. Deploy da Lambda**

```bash
cd terraform
terraform init
terraform apply \
  -var="neon_database_url=$NEON_DATABASE_URL" \
  -var="jwt_secret=$JWT_SECRET"
```

**Após o deploy**, copie a **Lambda Function URL** do output:
```
Outputs:
lambda_function_url = "https://xxxxx.lambda-url.us-east-1.on.aws/"
```

> ⚠️ **Guarde essa URL!** Você precisará dela para configurar o Kong Gateway.

### **3. Deploy Automático (atualizações futuras)**

Após o primeiro deploy manual:
1. Push na branch `main`
2. GitHub Actions executa deploy automaticamente
3. Lambda atualizada em ~2 minutos

---

## 🔐 Secrets Necessários

Configure no GitHub: **Settings → Secrets → Actions**

| Secret | Descrição |
|--------|-----------|
| `NEON_DATABASE_URL` | Connection string do Neon PostgreSQL |
| `JWT_SECRET` | Secret para geração de tokens JWT |
| `AWS_ACCESS_KEY_ID` | Credencial AWS para deploy |
| `AWS_SECRET_ACCESS_KEY` | Credencial AWS para deploy |

---

## 🧪 Como Testar

### **Endpoint da Lambda**
```
POST https://gazxy4ae3ittomlpjso27mbuni0popxn.lambda-url.us-east-1.on.aws/
```

### **Teste 1: CPF válido (200 OK)**
```bash
curl -X POST "https://gazxy4ae3ittomlpjso27mbuni0popxn.lambda-url.us-east-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}' \
  -w "\nHTTP Status: %{http_code}\n"
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "cliente": {
    "id": "b746aec4-455c-49b3-bcc2-838e2fb46f01",
    "nome": "João Silva"
  }
}
```

### **Teste 2: CPF não cadastrado (404)**
```bash
curl -X POST "https://gazxy4ae3ittomlpjso27mbuni0popxn.lambda-url.us-east-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"99999999999"}' \
  -w "\nHTTP Status: %{http_code}\n"
```

**Resposta:**
```json
{"error": "Cliente não encontrado"}
```

### **Teste 3: CPF inválido (400)**
```bash
curl -X POST "https://gazxy4ae3ittomlpjso27mbuni0popxn.lambda-url.us-east-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"cpf":"123"}' \
  -w "\nHTTP Status: %{http_code}\n"
```

**Resposta:**
```json
{"error": "CPF inválido"}
```

---

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

---

## 📝 Payload da API

### **Request**
```json
{
  "cpf": "12345678900"
}
```

### **Response (200)**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjxVVUlEPiIsImNwZiI6IjEyMzQ1Njc4OTAwIiwibm9tZSI6Ikpvw6NvIFNpbHZhIiwiaWF0IjoxNzY3NDk5ODE1LCJleHAiOjE3Njc1ODYyMTV9.xxx",
  "cliente": {
    "id": "b746aec4-455c-49b3-bcc2-838e2fb46f01",
    "nome": "João Silva"
  }
}
```

---

## 🔗 Recursos

- **Lambda Console**: https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions/oficina-mecanica-auth
- **CloudWatch Logs**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Foficina-mecanica-auth
- **Collection Postman**: [Em desenvolvimento]

---

## 📄 Licença

MIT - Tech Challenge 12SOAT Fase 3
