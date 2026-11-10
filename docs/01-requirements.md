# Requirements

PR-WKF-01 rev 3.0 implemented as a system. Source of truth for everything in this package.

## Purpose and scope

The system becomes the lab's record of its testing jobs. `JOB-2026-NNN_Workflow_Tracker.xlsx`
and its successors stop being the record and become an export the system generates.

It runs one process: PR-WKF-01 rev 3.0 — 11 stages, 25 steps, 51 requirements, 9 gates.
It holds a job from the contract review that accepts it to the closure that archives it,
and refuses to let a job move past a gate whose conditions are not met.

In scope:

- Contract reviews, jobs, and the stage/step/gate state of each job
- The 63-method ETSI library, per-job applicability and verdicts, and the roll-up that
  feeds report section 4
- The evidence register, deviations, planned QC, and information gaps
- Nonconforming work and complaints raised against a job
- Reports issued, and the sign-offs at gates 5, 7, 8 and 9
- Who did what, when, and what the value was before they changed it

Out of scope for v1: `Process_Control.xlsx` registers are referenced by ID rather than
replaced; the IXIT document stays a .docx; evidence files stay in the job folder; the
report is still written in Word. Also excluded: a client portal, scheduling and
resourcing (CipherOne already has a resource calendar), and generating the report
document from the record.

Because the database is the record, **ISO/IEC 17025 7.11.2 requires the system to be
validated for functionality before the first job runs on it**, and 7.11.3 requires it to
be protected from unauthorised access, safeguarded against tampering and loss, and
backed up. These are requirements, not afterthoughts.

## The four settled decisions

| Question | Decision | What it commits to |
|---|---|---|
| Where records live | In the system, on the server. Markdown and Excel are exports | 7.11.2 validation before first use; backup and restore proven; no silent deletes |
| What it is built on | Laravel + Filament + Livewire, the same stack as CipherOne | The prototype carries over; the lab module can fold into CipherOne later |
| How people sign in | Local accounts with TOTP, built so OIDC can be added | No dependency on CIPHER's directory; joiner and leaver handling is the lab's |
| Evidence files | Registered by metadata and path only; files stay in the job folder | Small storage, no duplicate custody, but the system cannot verify a SHA-256 |
| Hosting | Docker containers on an Ubuntu server in the home lab | Full control, but an accreditation assessor will ask about it |

## Records integrity

ISO/IEC 17025 7.5.2 is the hard constraint: an amendment to a technical record must be
traceable to the previous version, the original and amended data must both be retained,
and the amender must be identifiable. An application that updates rows in place does not
satisfy this.

- **Nothing is hard-deleted once controlled.** A record that never left draft can be
  deleted outright. From the moment it is submitted, referenced by another record, or
  sits under a passed gate, delete means archive: marked deleted with a reason and an
  actor, hidden from working lists, visible to the Quality Manager and the auditor role.
  The interface says *Archive*, not Delete.
- **Every change keeps its predecessor.** A history table per record table carrying the
  full previous row, the actor, the timestamp and a change reason where required.
- **The audit log is append-only.** Actor, action, object type and ID, before and after
  values, UTC timestamp, source IP, request ID. No role can edit or delete an entry,
  administrators included. Written in the same transaction as the change, and enforced
  at the database level by revoked grants plus a trigger — not by application code alone.
- **Gates are signed, not ticked.** Closing gate 5, 7, 8 or 9 requires re-entry of the
  signer's password or TOTP code. The record stores who signed, what they attested to,
  the gate's state at that instant, and the time.
- **A passed gate locks its stage.** Reopening requires a reason, is logged as an
  amendment, and prompts the Quality Manager to consider a nonconformity under 7.10.
- **Time.** NTP on the host. Store UTC, display Asia/Riyadh. Dates with contractual
  meaning (item received, testing performed, report issued) are entered as dates.

## Evidence handling

The system registers evidence; it does not hold it. Files stay in `03_Evidence` under
the job folder.

Each registration carries: evidence ID (`EV-nnn`, allocated by the system, never reused
within a job), type, description, path relative to the job folder, SHA-256 as recorded
by the collector, collection date, collector, the methods and IXIT entries it supports,
confidentiality marking, review status and retention period.

Two rules enforced on registration:

- **One registration per file.** The same path cannot be registered twice in a job, and
  the same SHA-256 cannot appear under two evidence IDs.
- **A verdict must cite evidence.** A tester verdict of PASS or FAIL with no evidence ID
  cannot be saved. INCONCLUSIVE must state what was missing.

**Known limitation.** Gate 7 requires every file in `03_Evidence` to be registered with a
matching SHA-256. The system never sees the directory and never reads the bytes, so it
can verify neither half. At gate 7 this remains a human attestation. A v1.1 candidate: a
command-line helper run on the test machine that walks the job folder, hashes every file
and posts the list to the API, letting the system report unregistered files, missing
files and changed hashes. It stores no file, so the register-only decision stands.

## ISO/IEC 17025 coverage

| Clause | Requirement | How the system meets it |
|---|---|---|
| 4.1 | Impartiality risks identified and minimised | `FR-COI-02` at gate 1; prior involvement recorded; separation of duties at gates 5, 7 and 11 |
| 4.2 | Confidentiality | Per-job access, TLP marking carried into exports, access revoked at gate 9 |
| 6.2 | Competence | Role assignment refuses anyone without an active, in-date authority flag |
| 6.4 | Equipment fit and calibrated | Gate 2 refuses equipment whose next due date precedes planned job end; gate 7 re-checks validity on actual test dates |
| 7.1 | Review of requests, decision rule agreed | Contract review record with decision, decision rule, authorization to test |
| 7.2 | Methods verified or validated; deviations authorised | Verification/validation record per method in use, checked at gate 5; deviations authorised in advance |
| 7.4 | Handling of items | Item receipt at gate 2, disposition at gate 9 |
| 7.5 | Technical records, amendments traceable | History tables, append-only audit log, no hard delete |
| 7.7 | Validity of results | QC planned at gate 5, logged as a gate 6 condition |
| 7.8 | Reporting | Report record with version, signatory, transmittal; section 4 counts bound to the roll-up; amendments create a new version |
| 7.9 | Complaints, independent handling | Stage 11 refuses an investigator or decision maker named on the job |
| 7.10 | Nonconforming work | Stage 10, with an NC able to block a named stage until closed |
| 7.11 | Data and information management | Validation before use; role-based and per-job access; database-level audit immutability; backup and tested restore |
| 8.3 | Control of documents | Workflow definition and method library versioned; a job pinned to the revision it started under |
| 8.4 | Control of records | Retention per record, archive at gate 9, auditor read access, export for retrieval |
| 8.5 / 8.7 | Risk and corrective action | NC links to the corrective action reference under `PR-CAP-01` |
| 8.6 | Improvement | Client feedback recorded at gate 9 |
| 8.8 | Internal audit | The auditor role and the audit trail export |

## Open questions — do not invent answers

1. **Home-lab hosting with accreditation in progress.** Either document the hosting as a
   controlled lab asset (physical security, network segregation, administration), or
   treat the home lab as build-and-validate and move to a CIPHER-controlled server
   before the first real job. Muhannad's choice, to be recorded.
2. **The evidence hash cannot be verified.** Accept the attestation, or add the helper.
3. **One administrator is a single point of failure and an impartiality question.**
   Mitigations: audit log immune to administrator edits, a second administrator held by
   someone else, administrator actions on job records reviewed by the Quality Manager.
4. **Method library revision.** The tracker's "How to Use" sheet cites Mapping **rev 1.1**;
   the file supplied is **rev 1.2**. Confirm which is controlled before seeding.
5. **Reviewer independence is unresolved in people terms.** Jobs will stop at gate 5
   until a deputy or external reviewer exists as a competence record. Intended behaviour.
6. **Historical jobs and their identifiers.** The lab already has JOB-2026-001 completed
   and others in flight, numbered before this system existed. But the design allocates
   every identifier itself and never lets one be typed, precisely so numbers cannot be
   reused or invented. If historical jobs are to live in the system, that needs a
   controlled backfill — a one-time import that sets the sequences and records who
   authorised each pre-existing number — not someone typing a job number into a form. The
   alternative is that historical jobs stay in the spreadsheets and the system starts from
   the next new job. Decide before the pre-production rebuild, because that is when the
   sequences are set.
7. **Values to confirm:** retention period from `PR-REC-CTRL-01`; RPO 24h and RTO one
   working day as proposed; number of accounts at the start; whether an Arabic interface
   is required or English-only is acceptable for v1.
