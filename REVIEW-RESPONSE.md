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

**4. Healthcheck — the finding was wrong, and so was this entry.** The review predicted
that `curl` was absent from the Alpine FrankenPHP image and would deadlock the stack on
`app: service_healthy`. It flagged the prediction as unverified, then retracted it after
building: **curl is present** at `/usr/bin/curl`, confirmed on both tags and in the built
image. This entry originally recorded the prediction as fact, which was a false statement
in what is becoming the controlled record of why decisions were made. Corrected 10 Nov
2026 after a second build session re-verified it. The Dockerfile still installs curl
explicitly, as insurance rather than as a fix.

A real defect did surface in the same area: the FrankenPHP base image ships its own
healthcheck polling Caddy's admin port, which `worker` and `scheduler` inherit and can
never satisfy, leaving both permanently in "starting". Disabled for those two services.

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

## Corrections to this document

This file is part of the record. When an entry in it turns out to be wrong, it is
corrected in place with the date and the reason, not quietly deleted — the same way an
amended technical record works under ISO/IEC 17025 7.5.2. Item 4 was corrected on
10 November 2026. The git history holds the previous wording.

## Not changed

**The method library stays at rev 1.2.** The session's reasoning is right: a job pins its
`method_library_version_id`, so if rev 1.1 turns out to be the controlled revision it
becomes a new revision row rather than a rewrite. Open question 4 stands.

**The version decision stays open.** The brief's fallback applies only once CipherOne has
genuinely been checked. See the reply in the conversation for the recommendation.

---

# Response to the slice-proof review — 11 November 2026

The build session proved the vertical slice, found a broken file in this package, and
found a gap in its own work. Changes made here:

**`infra/initdb/10-runtime-role.sql` was broken and failed silently.** It used
`:"POSTGRES_DB"`, but psql does not import environment variables as psql variables. The
syntax error aborted the rest of the file under `ON_ERROR_STOP`, so `ALTER DEFAULT
PRIVILEGES` and the guard function never ran — while the container still reported healthy,
two spot checks read true because PUBLIC holds CONNECT and USAGE by default, and Postgres
printed "Skipping initialization" on every later start rather than retrying. Corrected to
psql's built-in `:"DBNAME"`, with the trap documented in the file and a verification step
added to `infra/initdb/README.md` that checks for the guard function and the default ACL
entries rather than for the role.

**Item 4 above was a false statement and has been corrected in place.** See *Corrections
to this document*.

**Audit rows must name an actor.** The session found that 4 of 204 audit rows had a null
actor — bootstrap writes made before an actor was established — and that its own check had
passed only because it sampled the tail. Nothing in the design forced attribution.
`actor_id` is now NOT NULL at the column, a missing actor must throw, and genuine
bootstrap writes go through an explicit `actingAsSystem()` attributing to a named system
principal. Validation case 3 now requires every row to be checked, not a sample. This
matters more than its size suggests: the table is append-only, so an unattributed row can
never be repaired, and ISO/IEC 17025 7.5.2 requires the actor to be identifiable.

**Gates fail closed, and `Unevaluable` is now a state.** The session made an unimplemented
predicate mark a gate unevaluable rather than passed. That is better than this package
specified and is now the required behaviour, recorded in `gates.json` under
`evaluation_contract` and in the gate state list. A gate that passes because nobody wrote
its check asserts a control that was never applied.

**`job_provision_verdicts` has no history twin**, by design — it is derived from
`job_methods` and re-derivable. Recorded so a later reader does not "fix" it.

**`failed_jobs` and `job_batches` stay at Laravel's names.** Only `jobs` collides. The
earlier parenthetical suggesting all three be renamed traded config surface for cosmetic
consistency and has been withdrawn.

**Minor:** gate 7's rule 8 was listed twice in `docs/03-gate-rules.md`. De-duplicated.
`gates.json` was already clean.

## Not changed

**No Filament UI exists yet**, and slice item 3 says the steps and requirements should
"render and save". The session proved the save half and flagged the render half as not
done rather than letting it read as complete. The slice stays open until a page exists.

---

# Response to the attribution and fail-closed review — 11 November 2026

**The two instructions did collide, and the resolution is right.** NOT NULL at the column
and retaining rows that violate it cannot both hold: `SET NOT NULL` scans the table, and
the offending rows cannot be cleared because `UPDATE` on `audit_log` raises even for the
owner. `CHECK (actor_id IS NOT NULL)` added `NOT VALID`, upgraded to a literal `NOT NULL`
wherever the table is clean, satisfies both at the database level. Recorded in
`docs/02-data-model.md`.

**The data model did not carry the attribution requirement at all.** The session reported
that line 211 lacked `NOT NULL`; it was worse than that. The edit that was supposed to add
the whole *Every audit row must name an actor* section to `docs/02-data-model.md` was a
`replace()` whose search text did not match the file's line wrapping, so it silently did
nothing while the script reported success. The requirement existed only in
`REVIEW-RESPONSE.md` and the validation plan — exactly where someone building from the
normative data model would not see it. Now present, with every edit in that change
asserted rather than assumed.

**Reaching `Passed` is now specified as a deliberate transition.** The session found that
`Passed` was implied but never reachable: evaluation only ever produced `Open` or `Not
passed`. A separate close action now promotes to `Passed`, records actor and timestamp,
and is refused unless every machine rule is satisfied, every attestation signed and
nothing unevaluable. That is a better design than this package specified and is now part
of it.

**The known-defect question, answered by splitting the two runs.** The development proof
command may carry a named baseline of unrepairable defects, provided it fails if the count
rises and never reports them as a pass — a permanently red build is read exactly like a
permanently green one. The validation run that produces `VAL-WKF-01` demands zero, runs
against the clean database, and tolerates nothing. See `docs/06-validation-plan.md`.

**New open question 6: historical jobs and their identifiers.** The lab already has
JOB-2026-001 completed and others in flight, numbered before this system existed, while
the design allocates every identifier itself and never lets one be typed. Backfilling
them needs a controlled one-time import, not a form field. Decide before the
pre-production rebuild, because that is when the sequences are set.

---

# Response to the tracker page review — 11 November 2026

**Reviewed by rendering the snapshot and looking at both gate cards.** The signed
attestation reads as an assertion, not a verification. The devices that do the work: a
separately bordered box with a blue rail, a quill rather than a tick, no checkmark
anywhere on the card because the machine rules use coloured rule-id chips instead, the
explicit "The system cannot verify these", and a per-item "Asserted by *name* on *date* —
not verified by the system". The unsigned state reads correctly too: "Not yet attested —
needs a named person to assert it" is clearly an outstanding action, not a failed check.

**The prototype never covered attestations**, which the build session was right to flag —
`ui/prototype.html` renders only a gate statement and a pill, with no named reasons at
all, despite `UI_NOTES.md` claiming the gate box is where `blocked_reasons` go. The
three-box design is now recorded in `UI_NOTES.md` as the settled pattern, with the three
rules that carry the distinction, so it lives in the spec rather than only in the app.

**Two refinements recorded**, neither blocking: the signed state sets "not verified by
the system" in the quietest type on the card while the unsigned state shouts in amber —
the asymmetry runs the wrong way, since the signed case is the risky one. And the
attestation box should carry a count matching "8 of 8 conditions met".

---

# Response to the gate 7 spike and gate 3 mismatch — 11 November 2026

**Gate 3 rule 5 was unimplementable, and the fix is in the standard.** The build session
found that 19 of the 63 methods are unconditional *recommendations*, whose claim status is
a genuine supplier choice, while the data model nulled `ics_support` for every
unconditional method — leaving nowhere to record it. The error was requiring
`ics_support` only on the 37 conditional methods. TS 103 701 clause 4.4 gives **every**
provision a Support value: "Yes" claims it, "No" means applicable but not fulfilled with a
justification, and "N/A" is reserved for conditional provisions the DUT cannot fulfil. The
lab's own settled position agrees — every N/A verdict must trace to a Y/N/N-A declaration
in mapping column G. So `ics_support` is now required on all 63, `N-A` is constrained to
conditional methods, and `applicable = 'Y'` exactly where `ics_support = 'Y'` becomes
implementable. A new rule covers the clause 4.4 requirement that mandatory provisions be
claimed for overall PASS to be reachable.

Leaving the predicate out rather than guessing was the right call, and the fail-closed
design did exactly what it was built for.

**CLT-SCA-FI-01: exclude from the verdict chain, report separately — and this is a
method-status decision, not a scheme preference.** The session leaned toward including it
via a synthetic provision key, on the reasonable ground that excluding makes a FAIL
invisible. But Table 1 composes the overall verdict from provisions claimed "Yes" in the
ICS, and SCA/FI screening is scheme-defined rather than an EN 303 645 provision. Routing
it through Table 1 alters clause 4.6 verdict assignment — and DCN-2026-01 §2 records that
TS 103 701 remains a **standard method** under ISO/IEC 17025 7.2.1 precisely because
nothing alters verdict assignment, the provision set or a test unit. A change that does
converts it to a laboratory-modified standard method, requiring 7.2.2 validation and
client notification of deviation. That consequence is much larger than the placement of
one method.

The invisibility objection is answered by gate 8 rule 10: where a method excluded from the
chain carries FAIL or INCONCLUSIVE, the report must state that result explicitly. The
screening is reported beside the overall verdict rather than inside it. Recommended, for
Muhannad to ratify; until then the predicate refuses and names the method, which is
correct.

**One test case per group, today.** Every test group in Mapping rev 1.2 holds exactly one
test case — 62 provisions, 62 groups, all of size one — so Table 2's precedence logic
cannot aggregate anything and gate 7 rule 9 currently checks that a trivial mapping was
performed. Implementing Table 2 properly anyway, and asserting the one-per-provision
property against the seeded data so a later revision fails loudly, is the right response
and is now recorded in `gates.json`. Table 1 still genuinely aggregates 62 groups into one
overall verdict, so the middle level earns its place.

**Two deployment defects**, both surfaced by narrowing the Dockerfile's `chown` from the
whole application to `storage` and `bootstrap/cache`: Octane was writing
`public/frankenphp-worker.php` at boot, so the application had been rewriting its own
served assets; and FrankenPHP's embedded Caddy had no `$HOME` to persist state in, which
had been dismissed earlier as cosmetic log noise and was a real misconfiguration. Both
fixed in the application. The lesson worth keeping: a permissive `chown -R` hid two
posture defects, and tightening it is what exposed them.

---

# Method library rev 1.3, and a build defect in this package — 11 November 2026

**`CLT-SCA-FI-01` removed from the method library by lab decision.** Rev 1.3 holds **62
methods**: 36 conditional, 7 unconditional mandatory, 19 unconditional recommended, across
13 provision groups. That resolves the verdict-chain question by removing the method
rather than answering it, and it is the cleaner outcome — no synthetic provision key, no
exclusion policy to ratify, and TS 103 701 keeps its standard-method status under ISO/IEC
17025 7.2.1 untouched.

Keep the exclusion mechanism. Gate 7 rule 10 now passes vacuously, but it costs nothing
and it is what catches the next scheme-defined method before it distorts an overall
verdict. Drop only the seeded `CLT-SCA-FI-01` proposal row.

**Knock-on that needs a document change, not a code change:** PR-WKF-01 rev 3.0's gate
statements for gates 3 and 5 say "all 63 methods" verbatim, and the v3.0 tracker's sheet
04 totals 63. Those are quoted from controlled documents and have deliberately **not**
been edited here — `data/workflow.json` and `reference/` still carry the source text as
written. At PR-WKF-01's next revision the gate statements should stop hardcoding a count
and say "every method in the pinned library revision" instead, so the workflow and the
method library stop being coupled by a number.

**The panel rendered as unstyled HTML, and the cause was a commented-out line in this
package's Dockerfile.** `# RUN npm ci && npm run build` shipped disabled, and the image
had no Node to run it with. Filament compiles its CSS and JS through Vite, so without that
step there is no layout, no typography, and inline heroicon SVGs expand to fill the
viewport because the utility classes that size them were never generated. The three
hand-written lab stylesheets served from `public/` loaded perfectly throughout, which is
why it looked like a broken design rather than a missing build.

The Dockerfile now installs Node and runs the build after `composer install`, because
Filament's theme CSS imports from `vendor/filament`. `infra/DEPLOY.md` gains a three-part
check: the build manifest exists, Filament's own stylesheet is served, and the rendered
page references a built asset. The earlier verification — "all three lab stylesheets
served at the right sizes" — was true and proved nothing, because it checked only the
files the session had written itself.

**`ics_support` stays nullable at insert.** The build session's judgement was right: a job
opens with one empty row per method and the ICS is declared during stage 3, so a NOT NULL
column would make opening a job impossible. It is a gate-time requirement enforced by
`g3.r2`. The data model's "required on every row" has been reworded to say so.
