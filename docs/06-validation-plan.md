# Validation before first use (ISO/IEC 17025 7.11.2)

> A laboratory information management system shall be validated for functionality
> before use, including the proper functioning of interfaces.

Because the database is the record, this applies in full and before the first job — not
after. Validation does not mean testing everything. It means testing what, if wrong,
would corrupt a record or let a job past a gate it should not pass.

**Write these as the automated test suite.** The suite is the validation evidence, which
is why the tests matter more here than in an ordinary project.

## Test cases

1. **Gate rules, both directions.** For each of the nine gates: it passes when every
   condition is met, and it refuses *with the correct named reason* when any single
   condition is removed. That is 9 positive cases plus one negative case per rule.
2. **Separation of duties.** Each of the five rules in `04-roles-and-access.md`, tested
   by attempting the prohibited assignment or action and confirming refusal — through
   the UI path *and* through a direct model write, to prove the database enforces it.
3. **Record integrity.**
   - An amendment retains the previous value and names the amender.
   - An archived record stays retrievable by the Quality Manager and the auditor.
   - Connected **as the runtime role**, all five of `UPDATE`, `DELETE`, `TRUNCATE`,
     `ALTER TABLE ... DISABLE TRIGGER` and `DROP TRIGGER` on `audit_log` fail. Testing
     only that the trigger fires proves nothing: the table's owner can disable it.
   - A passed gate locks its stage; reopening requires a reason and writes an amendment.
   - **No audit row exists with a null actor.** Check every row, not a sample — the gap
     appears in bootstrap writes that happen before an actor is established, so a tail
     sample passes while the table is already contaminated. A write with no actor must
     throw rather than record null.
   - A gate with an unimplemented rule reads Unevaluable, not Passed.
4. **Identifier allocation.** No duplicate or reused job, evidence, report, NC or
   complaint identifiers, including under concurrent creation. Run it in parallel.
5. **Arithmetic.** The roll-up reconciles
   (`applicable = pass + fail + inconclusive + not_tested`) and the section 4 placeholder
   values match the underlying rows for a worked job.
6. **Export fidelity.** The tracker export reproduces sheets 01–07 of the v3.0 template
   field for field, checked against a worked job.
7. **Backup and restore.** A full restore into a clean container reproduces the database,
   verified by comparing a known job record and its audit trail.
8. **Interfaces.** Any integration that exists at v1 — at minimum the export generation
   path and the queue worker — behaves correctly when the dependency is slow or absent.

## Two modes, and only one may tolerate a known defect

The day-to-day proof command and the validation run are not the same thing, and
conflating them costs you either signal or evidence.

- **The development proof command** may carry a recorded baseline of known, unrepairable
  defects — audit rows that predate enforcement, for instance — provided it names each
  one, fails if the count ever rises, and never reports them as a pass. Its job is to say
  *something new broke*. A permanently red build is read exactly like a permanently green
  one.
- **The validation run that produces `VAL-WKF-01` demands zero.** No baseline, no
  tolerated residue, no known defects. It runs against the clean database that ISO 7.11.2
  requires before first production use, and either passes entirely or the system is not
  authorised for use.

Keeping both means red still means something during the build, while the evidence an
assessor reads carries no asterisks.

## Recording

Each case needs an expected result, an actual result, a tester, a date and a verdict.
The set becomes a controlled record — proposed reference `VAL-WKF-01` — and the system is
authorised for use by signature once every case passes.

## Parallel run

Recommended, not required by the standard: run the next job in both the system and the
v3.0 spreadsheet and compare. The spreadsheet is the control, the system is under test,
and the comparison is the strongest validation evidence available. It costs one job's
duplicated data entry and it is what makes the switchover defensible rather than asserted.

## Re-validation on change

A change to gate logic, roll-up arithmetic, identifier allocation or the export
templates requires the affected cases to be re-run before release. Other changes need
the regression set only.

Record the system version against each job, so a result can always be traced to the
logic that produced it. Git tags are the release record; the migration history is the
schema change record. Both are ISO 8.3 artefacts, not developer conveniences.
