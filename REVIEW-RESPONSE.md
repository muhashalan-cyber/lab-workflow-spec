# Response to the first build-session review — 10 November 2026

The Claude Code session on the Proxmox host reviewed this package before building and
found nine defects. Seven were real. This records what changed and what did not, so the
spec's history shows why.

## Fixed in the spec

**1. Audit immutability had a hole that would have passed a naive test.** `.env.example`
defined `DB_APP_ROLE` but nothing created it, and the application connected as
`DB_USERNAME`, which is the database owner. An owner can run
`ALTER TABLE audit_log DISABLE TRIGGER ALL` and then delete freely, so revoking rights
from an unused role protected nothing — while a tinker test would still have shown the
trigger firing. This was the most serious finding, and it is exactly slice item 5.
`docs/02-data-model.md` now specifies two roles (owner for migrations, non-owner runtime
role with SELECT and INSERT only on `audit_log`), and validation case 3 now requires all
five of UPDATE, DELETE, TRUNCATE, DISABLE TRIGGER and DROP TRIGGER to fail as the runtime
role.

**2. `initdb/10-audit-immutability.sql` did not install immutability.** Both triggers and
the REVOKE were commented out, and could not have lived there anyway: initdb runs before
migrations, when `audit_log` does not exist. Replaced by `initdb/10-runtime-role.sql`,
which creates the runtime role and the guard function, plus `initdb/README.md` giving the
exact statements the migration must end with and the five-statement proof.

**3. Dockerfile entrypoint.** `php artisan octane:frankenphp` corrected to
`octane:start --server=frankenphp`, with a note that Octane is not a default Laravel
dependency and must be required and installed, and that serving through FrankenPHP's own
Caddy config without Octane is an equally valid choice.

**4. Healthcheck would have deadlocked the stack.** `curl` is not in the Alpine
FrankenPHP image, so the healthcheck could never pass, and proxy, worker and scheduler all
wait on `app: service_healthy`. The Dockerfile now installs curl.

**5. Compose build context.** `context: ..` resolves to a directory with no
`composer.json` while `infra/` lives in the spec repo. Noted in the compose file and the
README: `infra/` belongs in the application repo.

**6. Eleven gate objects against "9 gates".** The session's proposed fix was right and is
now in the data rather than left to transcription: every gate object in `workflow.json`
carries `kind` (`sequence_gate` | `closing_condition`) and `blocks_sequence`. All 11 seed;
only 9 block progression.

**7. The gate rules existed only as prose.** The most important structural finding. They
are now extracted to `data/gates.json` — 11 gates, 79 machine rules, 12 attestations, each
with a stable id, a description and the failure message a blocked gate should show.
`docs/03-gate-rules.md` remains the reasoning behind them.

**8. The N-A conflict between gates 6 and 7.** Real, and the standard settles it rather
than the lab. ETSI TS 103 701 V1.1.1 Table 3 defines exactly three test case verdicts:
PASS, FAIL, INCONCLUSIVE. "N/A" belongs to the ICS Support column under clause 4.4 — it
describes applicability, not a result. So gate 6 now excludes N-A on applicable methods,
gate 7's reconciliation stands unchanged and needs no N-A term, and a check constraint
enforces it at the database rather than only at the gate. The earlier rule permitting
`verdict_tester = 'N-A'` on applicable methods was the defect.

**9. `job_gates.state` had no controlled list.** `gate_state` added to
`controlled-lists.json`, along with `stage_gate_kind` and notes recording which of the
five "verdict" values in tracker sheet 07 are actually test case verdicts.

## Found while fixing, not in the review

**The verdict chain is missing a level.** TS 103 701 assigns verdicts at three levels —
test case, test group (one per provision claimed Yes, Table 2), and overall (Table 1).
`job_methods` holds only the lowest. Without the middle level the report cannot state an
overall verdict. `job_provision_verdicts` added, with the derivation rules, and gate 7 and
gate 8 each gained a rule requiring the derivation.

**External evidence is not modelled.** Clause 4.7 lets a test group take PASS without
running its test cases when third-party evidence is adequate, with the laboratory
recording its examination of scope, test depth and coverage. Flagged in
`docs/03-gate-rules.md` as a v1 gap, not built.

## Not changed

**The method library stays at rev 1.2.** The session's reasoning is right: a job pins its
`method_library_version_id`, so if rev 1.1 turns out to be the controlled revision it
becomes a new revision row rather than a rewrite. Open question 4 stands.

**The version decision stays open.** The brief's fallback applies only once CipherOne has
genuinely been checked. See the reply in the conversation for the recommendation.
