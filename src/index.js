/**
 * Lambda Handler - Autenticação via CPF
 * Valida CPF, consulta cliente no Neon e retorna JWT
 */

const jwt = require("jsonwebtoken");
const { Client } = require("pg");

function validarCPF(cpf) {
  const cpfLimpo = cpf.replace(/[^\d]/g, "");
  return cpfLimpo.length === 11;
}

exports.handler = async (event) => {
  console.log("Event recebido:", JSON.stringify(event, null, 2));

  try {
    const body = JSON.parse(event.body || "{}");
    const { cpf } = body;

    if (!cpf || !validarCPF(cpf)) {
      return {
        statusCode: 400,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "CPF inválido" }),
      };
    }

    // Conectar no Neon
    const client = new Client({
      connectionString: process.env.NEON_DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });

    await client.connect();

    // Consultar cliente (usando cpfCnpj como no TypeORM)
    const cpfLimpo = cpf.replace(/[^\d]/g, "");
    const result = await client.query(
      'SELECT id, nome, "cpfCnpj" FROM clientes WHERE "cpfCnpj" = $1',
      [cpfLimpo]
    );

    await client.end();

    // Verificar se cliente existe
    if (result.rows.length === 0) {
      return {
        statusCode: 404,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ error: "Cliente não encontrado" }),
      };
    }

    const cliente = result.rows[0];

    const token = jwt.sign(
      {
        id: cliente.id,
        cpf: cliente.cpfCnpj,
        nome: cliente.nome,
      },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        token,
        cliente: {
          id: cliente.id,
          nome: cliente.nome,
        },
      }),
    };
  } catch (error) {
    console.error("Erro:", error);
    return {
      statusCode: 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: "Erro interno do servidor" }),
    };
  }
};
