-- Runs once, on first Postgres container start, before any migration.
-- Creates the non-owner role the application connects as at runtime.
--
-- Why two roles: a table's OWNER can run ALTER TABLE ... DISABLE TRIGGER ALL and then
-- delete freely, and REVOKE barely binds an owner. If the application connects as the
-- owner (which POSTGRES_USER gives you), audit immutability is one command from gone
-- while a trigger test still looks green. See docs/02-data-model.md.
--
--   owner role   = ${DB_USERNAME}     -> owns the schema, runs migrations only
--   runtime role = ${DB_APP_USERNAME} -> what the app, worker and scheduler connect as

-- psql does NOT import environment variables as psql variables. Pull them in through
-- a shell command, and use psql's own built-in :DBNAME for the current database --
-- :"POSTGRES_DB" is not set and raises a syntax error. An earlier revision of this file
-- made that mistake, and it failed SILENTLY: ON_ERROR_STOP aborted the rest of the file
-- while the container still reported healthy, two spot checks still read true because
-- PUBLIC holds CONNECT and USAGE by default, and Postgres prints "Skipping
-- initialization" on every later start, so it never retries. Verify this file ran by
-- checking for the guard function and the default ACL entries, not by the role existing.
\set app_user `echo "$DB_APP_USERNAME"`
\set app_pass `echo "$DB_APP_PASSWORD"`

CREATE ROLE :"app_user" LOGIN PASSWORD :'app_pass';

GRANT CONNECT ON DATABASE :"DBNAME" TO :"app_user";
GRANT USAGE ON SCHEMA public TO :"app_user";

-- Default privileges for tables the owner creates later, during migration.
ALTER DEFAULT PRIVILEGES FOR ROLE CURRENT_USER IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"app_user";
ALTER DEFAULT PRIVILEGES FOR ROLE CURRENT_USER IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO :"app_user";

-- The guard function the audit_log triggers call. The triggers themselves are created
-- by the migration that creates audit_log — they cannot live here, because this file
-- runs before any table exists.
CREATE OR REPLACE FUNCTION audit_log_is_append_only() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_log is append-only: % is not permitted', TG_OP;
END;
$$ LANGUAGE plpgsql;
