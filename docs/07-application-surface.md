# Application surface

What screens exist, who uses them, and what each lets a person do.

**This document was missing from the first package**, and its absence shaped the build.
The spec described data, rules and exports in detail but never said what the application
*is* from a desk, so the work went deep on the gate engine and thin on everything around
it. The result after the first fortnight was a correct enforcement core behind a single
read-only page — nobody could add a user, open a job, mark a step done, or export
anything.

Correctness first was the right order. This document is what stops it from being the
only order.

## Screens in v1

| Screen | Who uses it | What it does |
|---|---|---|
| **Lab Jobs** (list) | everyone, scoped to their jobs | The front door. Tabs by status, a row per job, and the action that opens a new one |
| **Job workflow tracker** | engineer, reviewer, signatory | The page that exists today, plus the write actions below |
| **Users & competence** | Lab Administrator, Quality Manager | Accounts, roles, and the `RG-CMP-01` competence records that authorise them |
| **Contract reviews** | Quality Manager, engineer | `CR-2026-NNN` records; a job is opened from an accepted one |
| **Evidence register** | engineer, reviewer | Per-job `EV-nnn` rows: path, hash, what they support |
| **Deviations, QC & gaps** | engineer, Quality Manager | Tracker sheet 06, three blocks |
| **Nonconformities & complaints** | Quality Manager | `NC-2026-NNN`, `CMP-2026-NNN`, with the independence rules enforced |
| **Reports** | signatory, reviewer | `REP-2026-NNN`, versions, sign-off, transmittal |
| **Exports** | everyone | Per `docs/05-exports.md`, generated in a queue worker |

## Lab Jobs: group by status, not by a flat list

A row of job chips does not survive forty jobs, let alone four hundred. The list is a
Filament resource with tabs, each a filter on `jobs.status` — the controlled values from
`controlled-lists.json`:

**Open · Testing · In review · Reported · Done · On hold**, plus **All**.

Two notes on the grouping:

- "Not started" is not a status. A job that exists is at least Open. If a *not started*
  grouping is wanted, derive it: **Open with zero gates passed**. Do not add a status
  value for it — the list is controlled and a derived filter costs nothing.
- Show the gate state in the row, not just the status. "Open" tells you nothing; "Open ·
  gate 2 not passed" tells you where it is stuck and who needs to act.

Columns: job, client, DUT, current stage, gate state, engineer, reviewer, planned end.
Default sort newest first. Quality Manager and Auditor see every job; everyone else sees
the jobs they are assigned to.

## Working the workflow: the write actions

This is what turns the tracker from a viewer into the system. Every one is an audited
write carrying an actor.

| Action | Who | Effect |
|---|---|---|
| Mark a requirement Complete or N/A | assigned engineer | With a note where N/A; re-evaluates the stage's gate |
| Mark a step Complete | assigned engineer | Records its record reference, responsible person and date |
| Record a tester verdict | assigned engineer | PASS / FAIL / INCONCLUSIVE, with at least one evidence ID |
| Record a reviewer and final verdict | Technical Reviewer | Refused if they did any of the work |
| Sign an attestation | the named person | Records who asserted it and when; never shown as a system check |
| Close a gate | depends on the gate | Refused unless every rule is satisfied, every attestation signed, nothing unevaluable |
| Reopen a passed gate | Quality Manager | Reason required; writes an amendment and prompts an NC decision |

Gates 5, 7, 8 and 9 additionally require re-authentication at the moment of closing, and
store the signature with what was attested and the gate's state at that instant.

## The review hand-off, concretely

"I mark the tasks and the technical manager reviews them" is modelled as follows, and the
system enforces it rather than relying on people remembering:

1. The **assigned engineer** sets requirement and step status, records evidence, and
   assigns tester verdicts. They cannot close gate 5 or 7 on their own job.
2. The **Technical Reviewer** opens the same tracker page and sees the review actions
   enabled: approve the test plan (gate 5), set reviewer and final verdicts, close gate 7.
   They are refused if they recorded any verdict or registered any evidence on that job.
3. The **Authorized Signatory** signs and issues the report at gate 8.

Nothing in the interface should offer an engineer a way to pre-approve their own work,
not even a disabled control with a tooltip. The separation is the point; showing it as a
greyed-out possibility invites someone to find the way around it.

## What a reviewer needs that an engineer does not

A review queue. "Which jobs are waiting on me?" is the reviewer's only real question, and
answering it from the Lab Jobs list means scanning. A filtered view — jobs where I hold
Technical Reviewer and a gate is open on me — is a small piece of work that decides
whether the review step happens promptly or becomes the thing everyone forgets.

## Not in v1

Client portal. Scheduling and resourcing — CipherOne already has a resource calendar.
Generating the report document; v1 produces the section 4 figures and the report is still
written in Word. Bulk editing. A mobile layout.
