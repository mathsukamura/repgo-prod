#!/bin/sh
set -e

echo "Aguardando PostgreSQL..."
until node -e "const pg=await import('pg');const p=new pg.default.Pool({connectionString:process.env.DATABASE_URL});await p.query('SELECT 1');await p.end();" 2>/dev/null; do
  sleep 1
done

# Cada migration roda com || true pra tolerar "already exists" em re-execucoes
echo "Aplicando migrate-base (database.sql)..."
node migrate-base.js || echo "migrate-base: ja aplicada, pulando."

echo "Aplicando migrate-billing (MIGRACAO-COBRANCAS.sql)..."
node migrate-billing.js || echo "migrate-billing: ja aplicada, pulando."

echo "Aplicando migrate-referrals (MIGRACAO-INDICACOES.sql)..."
node migrate-referrals.js || echo "migrate-referrals: ja aplicada, pulando."

echo "Aplicando migrate-assistance..."
node migrate-assistance.js || echo "migrate-assistance: ja aplicada, pulando."

echo "Aplicando seed..."
node -e "
import {readFile} from 'node:fs/promises';
import pg from 'pg';
const sql=await readFile('/seed.sql','utf8');
const pool=new pg.Pool({connectionString:process.env.DATABASE_URL});
try{await pool.query(sql);console.log('Seed aplicado.')}
catch(e){if(e.code==='23505')console.log('Seed já existe, pulando.');else throw e;}
finally{await pool.end();}
"

echo "Tudo pronto."
