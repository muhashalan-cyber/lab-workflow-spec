# Data model

PostgreSQL. Every table carries `id`, `created_at`, `updated_at`, `created_by`,
`updated_by`. Every table listed under "Record tables" also carries `deleted_at`,
`deleted_by`, `deleted_reason` (archive, never hard delete) and has a matching
`*_history` table holding the full previous row plus `changed_by`, `changed_at`,
`change_reason`.

Timestamps are `timestamptz`, stored UTC. Enumerated values come from
`data/controlled-lists.json` — use PostgreSQL enums or a lookup table, not free text.

## Versioned reference data

A job is pinned to the revisions it opened under. Reference rows are never edited in
place; a new revision is created.

**`workflow_definitions`** — `code` (PR-WKF-01), `revision` (3.0), `title`, `standard`,
`effective_from`, `effective_to`, `approved_by`, `approved_at`. Unique on (code, revision).

**`workflow_stages`** — `workflow_definition_id`, `number` (1–11), `title`, `sequential`
(bool — false for stages 10 and 11), `iso_refs`, `purpose`, `controlled_documents` (jsonb).

**`workflow_steps`** — `workflow_stage_id`, `code` ("1.1"), `title`, `guidance`,
`record_reference_label`, `record_reference_example`, `position`.

**`workflow_requirements`** — `workflow_step_id`, `position`, `text` (may contain inline
`<code>` markup from the source — render it, do not strip it).

**`workflow_gates`** — `workflow_stage_id`, `number` (1–11), `kind`
(`sequence_gate` | `closing_condition`), `blocks_sequence` (bool), `statement`,
`rules` (jsonb). **Seed all 11 rows** — stages 10 and 11 carry a closing condition that
gates their own closure, and discarding them would lose source text. Only the 9 rows with
`kind = 'sequence_gate'` block progression. Rules come from `data/gates.json`: 79 machine
rules and 12 attestations with stable ids. Store rule identity and messages here; keep
the predicates in code keyed by rule id.

**`method_library_versions`** — `revision` (1.2), `source_document`, `effective_from`,
`approved_by`. **`methods`** — `method_library_version_id`, `method_id`
(CLT-701-PWD-01), `provision_title`, `test_title`, `ts_ref`, `m_or_r`, `conditions`,
`steps_evidence`, `acceptance_criteria`, `tools`, `decision_rule_applies`,
`required_ixit`, `provision_group_clause`. Unique on (version, method_id).
Seed from `data/methods.json`; 63 rows, 37 with a non-empty `conditions`.

**`provision_groups`** — `clause`, `title`, `methods_in_library`. Seed from
`data/provision-groups.json`; totals must sum to 63.

## Identity and competence

**`users`** — standard Laravel plus `is_active`, `totp_secret`, `totp_confirmed_at`,
`recovery_codes_issued_at`. Roles and permissions via `spatie/laravel-permission`.

**`competence_records`** — `user_id`, `role` (enum: responsible_engineer, second_engineer,
technical_reviewer, authorized_signatory, quality_manager, lab_administrator, auditor),
`status` (Active/Suspended/Withdrawn), `authority_flag` (bool — e.g. *Can Perform
Technical Review*), `methods_authorized` (jsonb), `valid_from`, `valid_to`,
`basis` (training reference), `confirmed_by`, `confirmed_at`, `rg_cmp_reference`.

Role assignment reads this live. A gate closure snapshots the competence state as it
stood at that moment into the signature record.

## Clients and contract review

**`clients`** — `name`, `reference`, `notes`. **`client_contacts`** — `client_id`, `name`,
`email`, `phone`, `role`.

**`contract_reviews`** — `reference` (CR-2026-NNN, system-allocated), `client_id`,
`client_contact_id`, `client_own_reference`, `request_received_at`, `request_document_path`,
`scope_checked_against_sclab01` (bool), `out_of_scope_items`, `subcontracting_required`
(bool), `subcontractor`, `subcontract_client_approval_reference`, `coi_reference`
(FR-COI-02), `coi_risk_recorded_in_rgrsk01`, `confidentiality_reference` (FR-CONF-02),
`capability_confirmed`, `checklist_complete` (bool, CHK-CTR-01), `decision_rule`,
`statement_of_conformity_basis`, `authorization_to_test_path`,
`authorization_to_test_signed_at`, `destructive_testing_permitted` (bool),
`test_window_from`, `test_window_to`, `rules_of_engagement`, `escalation_contact`,
`decision` (Accept/Decline/Pending), `decided_by`, `decided_at`.

## Jobs

**`jobs`** — `reference` (JOB-2026-NNN), `contract_review_id`, `workflow_definition_id`,
`method_library_version_id`, `client_id`, `status` (job_status list), `classification_tlp`,
`job_folder_path`, `start_date`, `planned_end_date`, `actual_end_date`,
and the DUT block: `dut_description`, `manufacturer_model`, `serial_identifier`,
`firmware_as_received`, `firmware_at_end`, `constrained_device` (bool, per ICS).
Scope block: `standard_basis`, `test_specification`, `assessment_scope`,
`assessment_methodology`. Closure block: `archive_location`, `retention_period`,
`access_revoked_at`, `client_feedback_requested_at`.

**`job_roles`** — `job_id`, `user_id`, `role`, `assigned_by`, `assigned_at`,
`competence_record_id` (the record relied on). **Constraints:** unique on
(job_id, role) for single-holder roles; a user may not hold both an engineer role and
`technical_reviewer` on the same job — enforce in a policy *and* with a database check
or trigger, because this is the lab's open NC-2026-002.

**`job_equipment`** — tracker sheet 03A: `job_id`, `asset_id`, `name`, `serial_version`,
`use_on_job`, `calibration_required` (bool), `calibration_certificate_reference`,
`calibration_valid_to`, `valid_through_job_end` (computed against `jobs.planned_end_date`),
`out_of_tolerance_impact`, `checked_by`, `checked_at`.

**`job_environment_checks`** — sheet 03B: `job_id`, `check` (temperature, humidity,
power, rf_interference, physical_access, network_isolation), `requirement`,
`recorded_value`, `conforms` (bool), `record_reference`, `checked_by`, `checked_at`.

**`job_item_records`** — sheet 03C: `job_id`, `kind` (receipt, identification,
deviation_from_condition, storage_handling, configuration_changes, return_or_disposal),
`record`, `value`, `reference_notes`, `by_user_id`, `recorded_at`.

**`job_documents`** — sheet 04A: `job_id`, `kind` (ixit, mapping, tracker, report),
`file_name`, `version`, `document_date`, `approved_by`, `status`.

## Per-job workflow state

**`job_steps`** — `job_id`, `workflow_step_id`, `status` (workflow_status list),
`record_reference`, `responsible_user_id`, `completed_on`, `notes`.
Unique on (job_id, workflow_step_id). 25 rows per job.

**`job_requirements`** — `job_id`, `workflow_requirement_id`, `status`, `notes`,
`satisfied_by`, `satisfied_at`. Unique on (job_id, workflow_requirement_id). 51 rows per
job. **This granularity is what makes "which requirements are outstanding" answerable
and is what the gate rules read.**

**`job_gates`** — `job_id`, `workflow_gate_id`, `state` (Not reached / Open / Not passed /
Passed), `blocked_reasons` (jsonb — the named failing conditions), `attestations` (jsonb),
`passed_by`, `passed_at`, `signature_id`, `reopened_count`, `reopen_reason`.

## Methods and verdicts

**`job_methods`** — `job_id`, `method_id`, `ics_support` (Y/N/N-A, null where the method
carries no condition), `ics_declared_by`, `ics_declared_at`, `applicable` (Y/N),
`applicability_basis`, `verdict_tester`, `verdict_tester_by`, `verdict_tester_at`,
`verdict_reviewer`, `verdict_reviewer_by`, `verdict_reviewer_at`, `final_verdict`,
`tester_notes`, `reviewer_notes`. Unique on (job_id, method_id). 63 rows per job.

**`job_method_evidence`** — pivot `job_method_id` ↔ `evidence_id`. A PASS or FAIL
tester verdict with no row here must be refused at save time, not only at the gate.

**`job_provision_verdicts`** — `job_id`, `provision` (the `ts_ref` stem, e.g. `5.1-1`),
`group_verdict` (PASS/FAIL/INCONCLUSIVE), `basis` (derived | external_evidence),
`derived_at`. TS 103 701 assigns verdicts at three levels and `job_methods` holds only the
lowest. Derive the group verdict per Table 2 and the job's overall verdict per Table 1 —
see the verdict chain section in `03-gate-rules.md`. Never let anyone type either.

**Constraint:** a `job_methods` row with `applicable = 'Y'` may not carry
`verdict_tester` or `final_verdict` of `N-A`. N-A is an ICS Support value, not a test case
verdict. Enforce it with a check constraint, not only in the gate rule.

**Roll-up** is computed from `job_methods`, never stored as entered figures. The
reconciliation that must read OK before gate 8:
`applicable = pass + fail + inconclusive + not_tested`. The N/A column counts rows with
`applicable = 'N'` and sits outside the equation.

## IXIT

**`job_ixit_documents`** — `job_id`, `file_name`, `version`, `approved_by`, `approved_at`,
`document_date`, `classification`, `status`. The IXIT content stays in the .docx; the
system records the document and the observations against it.

## Evidence, deviations, QC, gaps

**`evidence`** — `job_id`, `reference` (EV-nnn, unique within job), `type`, `description`,
`path`, `sha256`, `collected_on`, `collected_by`, `confidentiality`, `review_status`,
`retention_disposal`, `notes`. **Unique on (job_id, path) and (job_id, sha256).**

**`method_deviations`** — sheet 06A: `job_id`, `reference`, `method_id`, `deviation`,
`technical_justification`, `client_informed` (bool), `authorized_by`, `authorized_at`,
`effect_on_verdict`. Must be authorised *before* the testing it covers.

**`qc_activities`** — sheet 06B: `job_id`, `reference`, `method_or_test`, `qc_type`,
`acceptance_criterion`, `result`, `departure_action`, `performed_by`, `performed_at`,
`process_control_reference`.

**`information_gaps`** — sheet 06C: `job_id`, `reference`, `ixit_or_method_reference`,
`observation`, `request_issued_at`, `raised_at`, `response_received_at`, `resolved`
(bool), `effect_on_verdict`, `blocking` (bool).

## Exceptions

**`nonconformities`** — `reference` (NC-2026-NNN), `job_id` (nullable), `description`,
`significance`, `immediate_action`, `affected_work_decision`, `client_informed` (bool),
`report_recalled_or_amended`, `resumption_authorized_by`, `resumption_authorized_at`,
`corrective_action_reference` (PR-CAP-01), `blocks_stage_number` (nullable — holds that
stage until closed), `closed_at`, `closed_by`, `outcome`,
`process_control_logged` (bool).

**`complaints`** — `reference` (CMP-2026-NNN), `job_id` (nullable), `complainant`,
`received_at`, `acknowledged_at`, `relates_to_lab_activities` (bool),
`investigator_id`, `investigation_notes`, `decision_maker_id`, `decision`,
`communicated_at`, `closed_at`. **Constraint:** `investigator_id` and
`decision_maker_id` must differ from each other and from every `job_roles.user_id` on
the related job (ISO 7.9.5 and 7.9.6).

## Reports

**`reports`** — `reference` (REP-2026-NNN), `job_id`, `version`, `file_name`,
`content_checklist` (jsonb — the 7.8.2 items), `decision_rule_stated` (bool),
`opinions_marked` (bool), `subcontracted_results_identified` (bool),
`signed_by`, `signed_at`, `signature_id`, `issued_at`, `transmittal_reference`,
`amends_report_id` (nullable — an amendment is a new version, never an overwrite).

## Integrity infrastructure

**`audit_log`** — `actor_id`, `action`, `object_type`, `object_id`, `before` (jsonb),
`after` (jsonb), `occurred_at`, `ip`, `request_id`. Written in the same transaction as
the change.

### Immutability needs two database roles, not one

A trigger alone does not make a table immutable. **A table's owner can run
`ALTER TABLE audit_log DISABLE TRIGGER ALL` and then delete freely**, and `REVOKE` barely
binds an owner at all. A superuser bypasses both. So if the application connects as the
database owner — which is what `POSTGRES_USER` gives you by default — the protection is
one command away from gone, while a naive test still shows the trigger firing. That test
would prove nothing.

Two roles:

- **Owner role** — owns the schema and runs migrations. Its credentials are used by the
  migration step and are not present in the running application's environment.
- **Runtime role** — a separate non-owner role the application connects as. On
  `audit_log` it holds `SELECT` and `INSERT` only: no `UPDATE`, no `DELETE`, no
  `TRUNCATE`, and no ownership, so it cannot disable the triggers either.

Then add `BEFORE UPDATE` and `BEFORE DELETE` triggers that raise an exception, as
defence in depth.

**The validation case is not "does the trigger fire".** It is: connecting as the runtime
role, every one of `UPDATE`, `DELETE`, `TRUNCATE`, `ALTER TABLE ... DISABLE TRIGGER` and
`DROP TRIGGER` on `audit_log` fails. Test all five.

**`signatures`** — `user_id`, `purpose` (gate_5, gate_7, gate_8, gate_9, report_issue),
`subject_type`, `subject_id`, `statement` (what was attested), `state_snapshot` (jsonb —
the gate's conditions as they stood), `reauthenticated_at`, `method` (password/totp),
`signed_at`, `ip`.

**`id_sequences`** — `kind` (contract_review, job, report, nonconformity, complaint),
`year`, `next_value`. Allocate inside a transaction with row locking. Never reuse a
value, including after an archive. Evidence IDs are per-job and allocated the same way.

## Record tables

These get `deleted_at`/`deleted_by`/`deleted_reason` and a `*_history` twin:
`contract_reviews`, `jobs`, `job_roles`, `job_steps`, `job_requirements`, `job_gates`,
`job_methods`, `job_equipment`, `job_environment_checks`, `job_item_records`,
`job_documents`, `job_ixit_documents`, `evidence`, `method_deviations`, `qc_activities`,
`information_gaps`, `nonconformities`, `complaints`, `reports`, `competence_records`.
