# initdb

`10-runtime-role.sql` runs once, on first Postgres container start, before migrations.
It creates the runtime role and the audit guard function.

**The audit triggers and the narrowed grant belong in the migration that creates
`audit_log`**, because nothing can be attached to a table that does not exist yet. That
migration must end with:

```sql
CREATE TRIGGER audit_log_no_update BEFORE UPDATE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION audit_log_is_append_only();
CREATE TRIGGER audit_log_no_delete BEFORE DELETE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION audit_log_is_append_only();

-- TRUNCATE needs a STATEMENT-level trigger: row-level triggers never fire for it.
CREATE TRIGGER audit_log_no_truncate BEFORE TRUNCATE ON audit_log
  FOR EACH STATEMENT EXECUTE FUNCTION audit_log_is_append_only();

-- The default privileges granted the runtime role full DML. Take it back on this table.
REVOKE ALL ON audit_log FROM <DB_APP_USERNAME>;
GRANT SELECT, INSERT ON audit_log TO <DB_APP_USERNAME>;
```

Then prove it, connected **as the runtime role**, not as the owner. All five must fail:

```sql
UPDATE audit_log SET action = 'x';
DELETE FROM audit_log;
TRUNCATE audit_log;
ALTER TABLE audit_log DISABLE TRIGGER ALL;
DROP TRIGGER audit_log_no_delete ON audit_log;
```

If any succeeds, the audit trail is not immutable and validation case 3 fails.

## Confirm this file actually ran

It can fail silently: `ON_ERROR_STOP` aborts the remainder, the container still reports
healthy, and Postgres prints "Skipping initialization" on every later start rather than
retrying. The role existing proves nothing, and `CONNECT`/`USAGE` read true for PUBLIC by
default. Check the two things only this file creates:

```sql
SELECT proname FROM pg_proc WHERE proname = 'audit_log_is_append_only';   -- 1 row
SELECT count(*) FROM pg_default_acl;                                      -- 2 entries
```

Neither present means the file aborted. Wipe the volume and re-run; a half-initialised
database is not a base to build a record system on.
