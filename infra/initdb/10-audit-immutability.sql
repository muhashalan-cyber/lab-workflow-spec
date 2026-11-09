-- Audit immutability, enforced by the database rather than by application code.
-- Runs on first container start, before migrations. The table is created by a
-- migration, so this file installs the guard function and a helper you call from
-- that migration's up() — adjust to whichever order you prefer, but do not leave
-- immutability to the application.

CREATE OR REPLACE FUNCTION audit_log_is_append_only() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append-only: % is not permitted', TG_OP;
END;
$$ LANGUAGE plpgsql;

-- After the audit_log table exists, run:
--
--   CREATE TRIGGER audit_log_no_update BEFORE UPDATE ON audit_log
--     FOR EACH ROW EXECUTE FUNCTION audit_log_is_append_only();
--   CREATE TRIGGER audit_log_no_delete BEFORE DELETE ON audit_log
--     FOR EACH ROW EXECUTE FUNCTION audit_log_is_append_only();
--   REVOKE UPDATE, DELETE ON audit_log FROM <DB_APP_ROLE>;
--
-- Then prove it from tinker. A validation case depends on this failing.
