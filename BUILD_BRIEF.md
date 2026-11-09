# Build brief

## Before you start

**Check the versions yourself.** This package was assembled on 9 November 2026, when
Laravel 13 (PHP 8.3+) and Filament 5 (PHP 8.2+, Laravel 11.28+, Tailwind 4.1+) were
current. Confirm before committing to majors.

**The version decision that matters.** CipherOne's markup looks like Filament 4. If the
lab module is eventually to live in the CipherOne codebase, match what CipherOne runs —
check its `composer.json` first. Starting on a different major is how that merge path
quietly closes. If CipherOne is not reachable from the server, build on current Laravel
and Filament and record the choice in the repo README so the decision is visible later.

**Confirm the host can reach** packagist.org, Docker Hub and the Filament docs before
planning the work. The sandbox that produced this package could not.

## Build order

The data model and the audit layer come first because retrofitting history and
immutability into a running system is painful and would invalidate earlier validation.

1. **Infrastructure.** `infra/docker-compose.yml` up with Postgres and Redis healthy,
   application container building, Caddy serving over TLS on the LAN hostname.
2. **Schema.** Every migration from `docs/02-data-model.md`, including the history
   tables and the audit table with its database-level immutability.
3. **Audit and history layer.** Model observers writing history rows; the audit table's
   UPDATE and DELETE grants revoked from the application role and a trigger blocking
   both. Prove it: try to tamper from `php artisan tinker` and confirm it fails.
4. **Reference data seeders.** `workflow.json`, `methods.json`, `provision-groups.json`,
   `controlled-lists.json`. The workflow definition is versioned data, not code.
5. **Users, roles, competence records**, and the policies in `docs/04-roles-and-access.md`.
6. **Jobs, stages, steps, requirements**, and the gate engine from `docs/03-gate-rules.md`.
7. **Methods, applicability and verdicts**, then the roll-up.
8. **Evidence, deviations, QC, information gaps.**
9. **Nonconformities and complaints**, including their independence rules.
10. **Reports and sign-off.**
11. **Exports** per `docs/05-exports.md`.
12. **The validation suite** from `docs/06-validation-plan.md`.

## Do the vertical slice first

Before building all eleven stages, prove the hardest pattern end to end:

1. A job exists with a Responsible Engineer and a Technical Reviewer assigned.
2. Assigning the same person to both roles is refused by a policy, with a readable
   reason. This is the direct fix for the lab's open NC-2026-002 and it is the pattern
   every other separation-of-duties rule follows.
3. Stage 1's three steps and their six requirements render and save.
4. Gate 1 refuses to pass while any condition is unmet, and names the specific
   condition that is missing — not a generic "gate not met".
5. Every one of those changes appears in the audit log with its actor and timestamp.

If that slice works, the remaining eight gates are repetition. If it does not, stop and
report before building further — the problem is structural.

## Things that will bite

- **The gate engine must be data, not scattered conditionals.** Conditions will be
  tuned for a year and every change triggers re-validation of the affected cases. One
  evaluator, rules as rows, each returning pass/fail plus the reason it failed.
- **A gate has two kinds of condition.** Machine-checkable, and human attestation where
  the system cannot verify (hash matches the file, adequacy judgements). Never render
  an attestation as if it were a check. `docs/03-gate-rules.md` separates them per gate.
- **Policies must consider job assignment, not just role.** "Is this user a Technical
  Reviewer?" is the wrong question. "Is this user the reviewer *on this job*, and did
  they do any of the work?" is the right one.
- **Identifiers are allocated by the system**, sequential within the year, never reused,
  never typed. Allocate inside a transaction and prove no duplicates under concurrency.
- **A passed gate locks its stage.** Reopening needs a reason, writes an amendment
  record, and should prompt the Quality Manager to consider a nonconformity.
- **Signatures at gates 5, 7, 8 and 9 require re-authentication** at the moment of
  signing, and record what was being attested plus the gate's state at that instant.

## Definition of done for v1

A job can be taken from contract review to closure entirely in the system; every gate
enforces its conditions; the audit trail is complete and tamper-evident; the tracker
.xlsx export reproduces sheets 01–07 faithfully; the validation suite passes; and a
restore from backup into a clean container reproduces the database.

## Report back

Muhannad is not a Laravel developer and is learning the stack alongside this build.
When you report progress, say what works, what you could not verify, and what decision
you need from him. Do not present untested code as working.
