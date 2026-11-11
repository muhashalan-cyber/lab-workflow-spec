# Roles, permissions and separation of duties

Roles mirror the authority flags in `RG-CMP-01`. A role alone never authorises an action
— the user must also hold an Active competence record with the matching flag, valid past
the job's planned end date.

## Permission matrix

| Role | May do | May not do |
|---|---|---|
| Lab Administrator | Manage accounts, reference data, system settings | Close any gate, set a verdict, sign a report |
| Quality Manager | Own registers, raise and close NC and complaints, document control, see every job, read the audit log | Close a technical gate on a job they tested |
| Responsible Engineer | Steps, ICS, IXIT records, methods, tester verdicts, evidence, deviations, QC on assigned jobs | Close gate 5 or 7 on their own job, sign a report |
| Second Engineer | As Responsible Engineer, on assigned jobs | As above |
| Technical Reviewer | Approve the test plan, set reviewer and final verdicts, close gates 5 and 7 | Be assigned as tester on the same job |
| Authorized Signatory | Sign and issue the report, close gate 8 | Sign for work they performed, absent a documented deputy arrangement |
| Auditor | Read every job, record, history row and the audit log; export | Change anything |

## Job administration: a separate authority from technical work (11 Nov 2026)

Creating, editing, archiving and moving jobs between the three sections is restricted to
**Lab Manager, Quality Manager and Technical Manager**. No engineer edits a job's
particulars — client, DUT, identifiers, assignments, dates — because those are what the
contract review accepted, and a job whose particulars drift away from its accepted scope
has broken the only link between what was agreed and what was tested.

Conversely, **marking work done is open to everyone assigned to the job**, and requires a
written confirmation stored against the job. This is deliberately wide: the person who did
the work is the person who should record it, and narrowing it to one named engineer means
the second engineer's work gets recorded by someone who did not do it.

The two settle together because they are different kinds of claim. *What this job is* is an
administrative fact set at contract review. *What was done on it* is a technical fact
recorded by whoever did it. Separation of duties sits at the gates, where a claim gets
checked by someone who did not make it, and is untouched by either of these.

> **Three role names need reconciling before implementation.** `RG-CMP-01` and
> `RG-PER-TASK-01` are authoritative. **Lab Manager** is confirmed real — it appears in
> ORG-STR-01 and in the CTO-to-Lab-Manager authorization letter — and is not the same
> thing as this document's *Lab Administrator*, which is a system-administration role.
> Whether **Technical Manager** is the same authority as *Technical Reviewer* or a
> distinct one is a question for the competence register. Do not guess a mapping in code;
> the authority flags in `RG-CMP-01` decide it, and if the register does not yet name
> these roles, that is a document change Muhannad owns.

The auditor role exists for SAAC assessors. A time-boxed read-only account beats
exporting screenshots, and the account's own activity is logged like anyone else's.

## The five rules the system enforces

1. A user holding `responsible_engineer` or `second_engineer` on a job cannot be
   assigned `technical_reviewer` on that job, or the reverse. **This is the fix for the
   lab's open NC-2026-002.**
2. Gate 7 cannot be closed by anyone who recorded a tester verdict or registered
   evidence on that job.
3. A complaint cannot be investigated by anyone named in `job_roles` for the job it
   concerns (ISO 7.9.5), and the decision maker must differ from the investigator
   (ISO 7.9.6).
4. A role can only be assigned to a user whose competence record is Active, carries the
   matching authority flag, and does not expire before `jobs.planned_end_date`.
5. Where no eligible person exists, the job **blocks at the gate and says so**. It does
   not warn and continue. A deputy or external reviewer is a competence record like any
   other.

Implement 1–4 as Laravel policies *and* as database constraints or triggers where the
shape allows. A policy alone is bypassable by a console command or a future developer;
the database is not. Rule 5 is the absence of a bypass, which is itself the requirement.

## Per-job access

Access is per job, not global. A user sees jobs they are assigned to. Quality Manager
and Auditor see all.

- Assigning someone to a job grants their access and writes the `RG-ACC-01` entry.
- Closing the job at gate 9 revokes it and writes the revocation.

That turns "access revoked" at gate 9 from a manual checkbox into a recorded system
event, which is what makes it evidence.

## Classification

Each job carries a TLP marking. Exports inherit it and stamp it into the generated file.
A TLP: AMBER+STRICT job must not produce an unmarked export.

## Authentication

Local accounts with TOTP mandatory for every account that can close a gate, sign, or
read another engineer's job. Argon2id password hashing, session idle timeout, and
re-authentication at signature points (gates 5, 7, 8, 9 and report issue). Recovery
codes issued once, and the issuance recorded.

Build the identity layer so an OIDC provider can be added later without reworking
authorisation — keep role and competence logic independent of how the user authenticated.
