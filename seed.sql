-- Seed de teste para o RepGo.
-- Substitua nGuXW6KGrBchMO9UHTv7f4G5zW82 pelo UID real do usuario no Firebase Auth.
-- Para encontrar: Firebase Console > Authentication > Users > copiar o UID.

BEGIN;

INSERT INTO representatives(id, name, email, active)
VALUES ('nGuXW6KGrBchMO9UHTv7f4G5zW82', 'Representante Teste', 'mathsu.dev@gmail.com', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO memberships(firebase_uid, representative_id, role, capabilities, active)
VALUES ('nGuXW6KGrBchMO9UHTv7f4G5zW82', 'nGuXW6KGrBchMO9UHTv7f4G5zW82', 'admin', '[]'::jsonb, true)
ON CONFLICT (firebase_uid) DO NOTHING;

-- Cliente de exemplo
INSERT INTO clients(representative_id, id, data)
VALUES ('nGuXW6KGrBchMO9UHTv7f4G5zW82', 'c-seed-001', '{"name":"Cliente Exemplo Ltda","razaoSocial":"Cliente Exemplo Ltda","document":"12.345.678/0001-90","city":"São Paulo","state":"SP","phone":"11999990000","email":"cliente@exemplo.com"}')
ON CONFLICT (representative_id, id) DO NOTHING;

-- Produto de exemplo
INSERT INTO products(representative_id, id, data)
VALUES ('nGuXW6KGrBchMO9UHTv7f4G5zW82', 'p-seed-001', '{"name":"Produto Teste","code":"PT-001","price":150.00,"unit":"un"}')
ON CONFLICT (representative_id, id) DO NOTHING;

-- Pedido de exemplo
INSERT INTO orders(representative_id, id, client_id, data)
VALUES ('nGuXW6KGrBchMO9UHTv7f4G5zW82', 'o-seed-001', 'c-seed-001', '{"status":"Em aberto","items":[{"productId":"p-seed-001","name":"Produto Teste","quantity":10,"price":150.00}],"total":1500.00,"createdAt":"2026-10-15T12:00:00Z"}')
ON CONFLICT (representative_id, id) DO NOTHING;

COMMIT;
