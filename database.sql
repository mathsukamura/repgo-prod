-- PostgreSQL. Run once on a NEW database; does not migrate existing deployments.
-- Legacy RepGo IDs have prefixes (u-, c-, o-), so identifiers are TEXT, not UUID.
BEGIN;
CREATE TABLE representatives(id text PRIMARY KEY, name text NOT NULL, email text NOT NULL UNIQUE, active boolean NOT NULL DEFAULT true);
CREATE TABLE memberships(firebase_uid text PRIMARY KEY, representative_id text NOT NULL REFERENCES representatives(id), owner_representative_id text REFERENCES representatives(id), role text NOT NULL CHECK(role IN ('admin','rep','preposto')), capabilities jsonb NOT NULL DEFAULT '[]'::jsonb, active boolean NOT NULL DEFAULT true,
  CHECK ((role <> 'preposto' AND owner_representative_id IS NULL) OR (role = 'preposto' AND owner_representative_id IS NOT NULL)));
CREATE TABLE bling_connections(representative_id text PRIMARY KEY REFERENCES representatives(id), token_ciphertext text NOT NULL, updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE products(representative_id text NOT NULL REFERENCES representatives(id), id text NOT NULL, bling_id text, data jsonb NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(representative_id,id), UNIQUE(representative_id,bling_id));
CREATE TABLE clients(representative_id text NOT NULL REFERENCES representatives(id), id text NOT NULL, bling_id text, data jsonb NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(representative_id,id), UNIQUE(representative_id,bling_id));
CREATE TABLE orders(representative_id text NOT NULL REFERENCES representatives(id), id text NOT NULL, client_id text, bling_id text, data jsonb NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(representative_id,id), UNIQUE(representative_id,bling_id), FOREIGN KEY(representative_id,client_id) REFERENCES clients(representative_id,id));
CREATE TABLE business_records(representative_id text NOT NULL REFERENCES representatives(id), resource text NOT NULL CHECK(resource IN ('deals','tasks','goals','cycles')), id text NOT NULL, data jsonb NOT NULL, updated_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(representative_id,resource,id));
CREATE TABLE integration_links(representative_id text NOT NULL REFERENCES representatives(id), resource text NOT NULL, repgo_id text NOT NULL, bling_id text NOT NULL, PRIMARY KEY(representative_id,resource,repgo_id), UNIQUE(representative_id,resource,bling_id));
CREATE TABLE sync_queue(representative_id text NOT NULL REFERENCES representatives(id), id text NOT NULL, resource text NOT NULL, record_id text NOT NULL, payload jsonb NOT NULL, status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processing','done','conflict','failed')), attempts integer NOT NULL DEFAULT 0, next_attempt_at timestamptz NOT NULL DEFAULT now(), last_error text, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(representative_id,id));
CREATE TABLE oauth_states(nonce text PRIMARY KEY, representative_id text NOT NULL REFERENCES representatives(id), expires_at timestamptz NOT NULL);
CREATE INDEX sync_queue_pending ON sync_queue(next_attempt_at) WHERE status='pending';
-- The authenticated server sets app.representative_id inside each transaction.
-- Runtime role must NOT be superuser, table owner or have BYPASSRLS.
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['products','clients','orders','business_records','integration_links','sync_queue','bling_connections'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY tenant_scope ON %I USING (representative_id = current_setting(''app.representative_id'', true)) WITH CHECK (representative_id = current_setting(''app.representative_id'', true))', t);
  END LOOP;
END $$;
COMMIT;
