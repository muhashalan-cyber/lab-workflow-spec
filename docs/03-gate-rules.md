# The nine gates as machine rules

A gate is a precondition on a state transition. A job cannot enter stage *n+1* until
gate *n* reads **Passed**, and a gate reads Passed only when every rule below evaluates
true and every attestation has been signed.

## How to implement this

One evaluator, rules as data. Each rule returns `{passed, reason}` where `reason` names
the specific thing that is missing — "method CLT-701-UPD-04 has no tester verdict", not
"gate not met". `job_gates.blocked_reasons` holds the failing reasons as jsonb so the UI
can list them as links to the records that need fixing.

Suggested rule shape in `workflow_gates.rules`:

```json
{
  "machine": [
    {"id": "g5.r4",
     "description": "Test plan approved by a Technical Reviewer who is not a tester on the job",
     "failure": "No Technical Reviewer has approved the test plan",
     "severity": "blocking"}
  ],
  "attestations": [
    {"id": "g5.a1", "statement": "The plan's setup and network topology are workable"}
  ]
}
```

Keep the predicate itself in PHP, keyed by rule id, so a rule change is a code change
that triggers re-validation of that case — which is what ISO 7.11.2 expects.

**Never render an attestation as a check.** The UI must distinguish "the system verified
this" from "a named person asserted this at a timestamp".

---

## Gate 1 — Intake and contract review

> CR-2026-XXX exists, Decision = Accept, and the written Authorization to Test is filed
> in `00_Contract`. Without all three, no technical work begins.

**Machine rules**

1. A `contract_reviews` row exists and is linked to the job.
2. `decision = 'Accept'`, with `decided_by` and `decided_at` set.
3. `authorization_to_test_path` is not null and `authorization_to_test_signed_at` is set.
4. `checklist_complete = true` (CHK-CTR-01).
5. `coi_reference` and `confidentiality_reference` are both present.
6. `decision_rule` and `statement_of_conformity_basis` are both non-empty.
7. Every `job_requirements` row for stage 1 is Complete or N/A.
8. If `subcontracting_required`, then `subcontract_client_approval_reference` is present.

**Attestation** — the scope was genuinely checked against `SC-LAB-01` and out-of-scope
items excluded or subcontracted.

## Gate 2 — Job setup and readiness

> JOB-2026-XXX is open, the job file exists, roles are authorized, the item and equipment
> are recorded as fit, and the three job documents exist with a version.

**Machine rules**

1. `jobs.reference` allocated and `job_folder_path` set.
2. `job_roles` holds a responsible_engineer, a technical_reviewer and an
   authorized_signatory.
3. For each, the linked `competence_records` row is Active, carries the right
   `authority_flag`, and `valid_to` is null or **after `jobs.planned_end_date`**.
4. No user holds both an engineer role and technical_reviewer on this job.
5. A `job_item_records` row of kind `receipt` exists with a value and a recorder.
6. At least one `job_equipment` row exists, and **every** row with
   `calibration_required` has `calibration_valid_to > jobs.planned_end_date`.
7. All six `job_environment_checks` rows exist with `conforms` set.
8. `job_documents` holds rows of kind ixit, mapping and tracker, each with a version.
9. Stage 2 requirements all Complete or N/A.

**Attestations** — item condition judgement; the bench, isolated test network and
least-privilege access are genuinely in place.

## Gate 3 — DUT identification and the ICS

> Every conditional method carries an ICS Support value, every one of the 63 methods
> carries an applicability decision with its basis, and every N has been challenged and
> accepted by the laboratory.

**Machine rules**

1. `job_methods` holds exactly 63 rows for the job.
2. Every row whose method has `conditional = true` has `ics_support` in (Y, N, N-A),
   with `ics_declared_by` and `ics_declared_at` set. **37 rows in rev 1.2.**
   *Do not test `conditions` for emptiness:* 26 of the 63 carry the literal string
   `N/A` in the Conditions column, meaning unconditional. `data/methods.json` carries
   a normalised `conditional` boolean and nulls `conditions` on those 26 — use it.
3. Every row has `applicable` in (Y, N).
4. Every row has a non-empty `applicability_basis`.
5. `jobs.constrained_device` is not null.
6. The DUT block on `jobs` is complete: manufacturer_model, serial_identifier,
   firmware_as_received. Fields the client did not supply are recorded as
   "Not provided" with a reason — never left null.
7. A `job_ixit_documents` row exists (section 1 and 2 complete).
8. No `information_gaps` row with `blocking = true` is unresolved.

**Attestation** — each N was challenged against its condition and against IXIT section 2.

## Gate 4 — IXIT completion and adequacy review

> Every IXIT entry named by an applicable method is present at entry-per-mechanism
> granularity, with its information source recorded, and the IXIT document is approved
> at an issue version.

**Machine rules**

1. `job_ixit_documents` row has `version`, `approved_by` and `approved_at` set.
2. For every `job_methods` row with `applicable = 'Y'`, the IXIT types named in
   `methods.required_ixit` are recorded as present. (Parse `required_ixit`; it is prose
   with identifiers such as `IXIT 1-AuthMech`. Normalise it into a lookup table during
   seeding rather than parsing at evaluation time.)
3. Every `information_gaps` row raised against an IXIT entry is either resolved, or
   carries a stated `effect_on_verdict`.
4. No required IXIT entry is recorded as empty.
5. Stage 4 requirements all Complete or N/A.

**Attestation** — adequacy of the content itself, which is a judgement.

## Gate 5 — Method selection and the test plan

> Applicability is complete for all 63 methods, verification or validation records exist
> for every method in use, deviations are authorized, and the Technical Reviewer has
> approved the plan.

**Machine rules**

1. Gate 3 passed (applicability complete).
2. For every method with `applicable = 'Y'`, a verification or validation record exists
   under PR-MET-01.
3. Every `method_deviations` row has `authorized_by` and `authorized_at` set, and
   `authorized_at` precedes any tester verdict on that method.
4. At least one `qc_activities` row is planned, each with an `acceptance_criterion`.
5. **The test plan is approved by a user who holds technical_reviewer on this job and
   holds no engineer role on it.** Record name and date.
6. Stage 5 requirements all Complete or N/A.

**Attestation** — the plan's setup and topology are workable.

> This is the gate the lab currently blocks on: `RG-CMP-01` authorises one person for
> all three roles, so rule 5 cannot be satisfied until a deputy or external reviewer
> exists. That is intended. Do not add a bypass.

## Gate 6 — Assessment execution and evidence

> Every applicable method has a tester verdict, every verdict names at least one
> registered Evidence ID, every evidence file is registered once with a hash, and
> planned QC is logged.

**Machine rules**

1. Every `job_methods` row with `applicable = 'Y'` has a `verdict_tester` from the
   controlled list.
2. Every such row with verdict PASS or FAIL has at least one `job_method_evidence` row.
3. Every INCONCLUSIVE verdict has non-empty `tester_notes` stating what was missing.
4. `verdict_tester = 'N-A'` only where `ics_support = 'N'` or `'N-A'` traces to the ICS.
5. Every `evidence` row has a non-empty `sha256`; uniqueness of (job, path) and
   (job, sha256) is enforced by the schema.
6. Every planned `qc_activities` row has a `result` and a `performed_by`.
7. Every `method_deviations` row used during execution was authorised before the verdict.
8. Stage 6 requirements all Complete or N/A.

**Attestations** — that each SHA-256 matches the file on disk, that no file in
`03_Evidence` is unregistered, and that the conceptual assessment was sound. *The system
cannot verify the first two — see the limitation in `01-requirements.md`.*

## Gate 7 — Technical review

> Every tested method carries a reviewer verdict and a Final Verdict, the tracker counts
> reconcile, and the reviewer has signed the review record.

**Machine rules**

1. The reviewer holds technical_reviewer on this job, holds no engineer role on it, and
   recorded no tester verdict and registered no evidence on it.
2. Every method with `applicable = 'Y'` has `verdict_reviewer` and `final_verdict` set.
3. Every method with `applicable = 'N'` has an `applicability_basis` consistent with its
   `ics_support` value.
4. Every final verdict's method names at least one `evidence` row that exists.
5. **Reconciliation reads OK:** `count(applicable='Y') = pass + fail + inconclusive +
   not_tested`.
6. For every method with a verdict, the equipment used was calibration-valid on the
   recorded test date (`job_equipment.calibration_valid_to >= verdict date`).
7. Every planned QC activity has been performed.
8. Stage 7 requirements all Complete or N/A, and a signature exists.

**Attestation** — no PASS rests on evidence that does not support it.

## Gate 8 — Reporting

> The report is signed by an Authorized Signatory, logged as REP-2026-XXX, and issued
> with the transmittal recorded.

**Machine rules**

1. Gate 7 passed.
2. A `reports` row exists with `reference`, `version` and `file_name`.
3. Every item in `content_checklist` (the 7.8.2 list) is true.
4. `decision_rule_stated`, `opinions_marked` and, where applicable,
   `subcontracted_results_identified` are all true.
5. `signed_by` holds authorized_signatory on this job with a valid competence record,
   and a `signatures` row exists for purpose `report_issue`.
6. The report's section 4 figures equal the computed roll-up exactly.
7. `issued_at` and `transmittal_reference` are set.

**Attestation** — every placeholder replaced, Annex T removed, TLP marking consistent on
cover, header and footer.

## Gate 9 — Closure

> Item disposed of as agreed, job file archived with retention applied, access revoked,
> Job_Register Status = Done.

**Machine rules**

1. A `job_item_records` row of kind `return_or_disposal` exists with date and recipient.
2. `jobs.archive_location` and `jobs.retention_period` are set.
3. `jobs.access_revoked_at` is set and every `job_roles` access grant is revoked.
4. `jobs.client_feedback_requested_at` is set.
5. `jobs.status = 'Done'` and `actual_end_date` is set.
6. No open `nonconformities` row blocking this job.
7. Stage 9 requirements all Complete or N/A.

**Attestation** — client data held outside the archive has been securely deleted.

---

## Stages 10 and 11 — closing conditions, not sequence gates

These attach to a job at any point and never block the sequence by position. What blocks
is an open nonconformity that names a stage.

**Stage 10, nonconforming work** closes when: the decision on affected work is recorded,
the client informed where a report was affected, resumption authorised in writing, and
the NC closed with an outcome. If `blocks_stage_number` is set, that stage cannot
progress until `closed_at` is set.

**Stage 11, complaints** closes when the outcome is decided by people not involved in
the original activity, communicated formally, and the complaint closed. Enforce
`investigator_id ≠ decision_maker_id`, and neither may appear in `job_roles` for the
related job.
