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

## Lab Jobs: three sections, and what you can do in each

Decided 11 November 2026. Three tabs, not six, each with its own actions:

| Section | What it holds | Actions |
|---|---|---|
| **Not started** | A job that exists but has not passed gate 1 | Create a job, edit every detail, **delete it outright** |
| **Open** | Gate 1 passed, work underway | Archive it with a reason; move it back to Not started |
| **Closed** | Gate 9 passed, status Done | Archive it with a reason; move it back to Open |

### Why "delete" only appears in Not started

A job in **Not started** has never been a controlled record. Nothing was accepted,
nothing was authorised, no technical work happened. Deleting it is removing a typo, and
the data model already allows exactly this: a record that has never left draft can be
deleted outright.

The moment gate 1 passes, that stops being true. A contract review was accepted, an
Authorization to Test was signed, and a client is on the other side of it. From there,
**delete means archive**: the job leaves the working lists, keeps its identifier, and
stays readable by the Quality Manager and the auditor, with a reason and an actor
recorded. The button still says what it does — *Archive* — rather than saying Delete and
doing something else.

This is not caution for its own sake. "What happened to JOB-2026-014?" is a question an
assessor can ask, and "someone deleted it" is the one answer that cannot be given.

### Moving a job backwards

- **Open → Not started** reopens gate 1. It needs a reason, writes an amendment, and the
  gate's previous pass stays in the history.
- **Closed → Open** after a report has been issued is nonconforming work under ISO/IEC
  17025 7.10, and an issued report that needs changing is 7.8.8 territory. The action
  requires a reason and **raises or links a nonconformity**. It must not be a quiet
  status change: the whole point of closing a job is that reopening it is an event.

Both moves are available to the roles below, nobody else.

## Who can do what

Decided 11 November 2026.

**Editing a job** — creating it, changing its details, archiving it, moving it between
sections — is restricted to **Lab Manager, Quality Manager and Technical Manager**.

**Marking work done** is open to everyone assigned to the job. Completing a requirement
or a step requires the person to **write a confirmation of what they did**; it is stored
against the job, carries their name and the time, appears in the tracker and in the
.xlsx export, and cannot be left blank. A tick records that someone clicked; a
confirmation records what was done, and only the second is evidence.

> **Role names need reconciling before this is built.** `RG-CMP-01` and `RG-PER-TASK-01`
> are the authoritative source for what roles the lab actually has. The spec currently
> names Lab Administrator, Quality Manager, Responsible Engineer, Second Engineer,
> Technical Reviewer, Authorized Signatory and Auditor. "Lab Manager" appears in
> ORG-STR-01 and in the CTO-to-Lab-Manager authorization letter, so it is real. Whether
> "Technical Manager" is the same authority as Technical Reviewer or a separate one is a
> question for the competence register, not for the code. Do not invent a mapping.

### This does not weaken separation of duties

Everyone marking tasks done is about *recording work*, not approving it. Gates 5 and 7
still require a Technical Reviewer who did none of the work, and gate 8 still requires an
Authorized Signatory. Anyone reading "all can mark the tasks as done" as softening the
reviewer rule has read it wrong: marking a step complete is a claim, and the gate is
where the claim gets checked by someone else.

## How the three sections map onto `jobs.status`

The three sections are a **derived grouping**, not three new status values. The controlled
list in `controlled-lists.json` is unchanged — Open · Testing · In review · Reported ·
Done · On hold — and the tabs filter it:

| Section | Derivation |
|---|---|
| Not started | gate 1 not passed |
| Open | gate 1 passed and status is not Done |
| Closed | status Done |
| Archived | `archived_at` is set — visible to Quality Manager and Auditor only |

A row of job chips does not survive forty jobs, let alone four hundred, so this is a
Filament resource with tabs, and the underlying status stays visible as a column: three
sections answer "where is this in its life", the status column answers "what is it doing
right now", and the two are not the same question.

Show the gate state in the row, not just the status. "Open" tells you nothing; "Open ·
gate 2 not passed" tells you where it is stuck and who needs to act.

Columns: job, client, DUT, current stage, gate state, engineer, reviewer, planned end.
Default sort newest first. Quality Manager and Auditor see every job; everyone else sees
the jobs they are assigned to.

**Creating a job happens in Not started**, with every detail editable there: client, DUT,
identifiers, assigned engineer, reviewer, dates. This is the only section where the job is
still a draft, and the Create action belongs on that tab rather than floating above all
three.

## Working the workflow: the write actions

This is what turns the tracker from a viewer into the system. Every one is an audited
write carrying an actor.

| Action | Who | Effect |
|---|---|---|
| Create a job, edit its details | Lab Manager, Quality Manager, Technical Manager | Only these three roles; see *Who can do what* |
| Delete a Not started job | Lab Manager, Quality Manager, Technical Manager | Hard delete, permitted only before gate 1 |
| Archive an Open or Closed job | Lab Manager, Quality Manager, Technical Manager | Reason required; the job stays readable |
| Move Open → Not started | Lab Manager, Quality Manager, Technical Manager | Reopens gate 1; reason required; writes an amendment |
| Move Closed → Open | Lab Manager, Quality Manager, Technical Manager | Reason required; raises or links a nonconformity (ISO 7.10) |
| Mark a requirement Complete or N/A | anyone assigned to the job | **Written confirmation required**; stored with the job; re-evaluates the gate |
| Mark a step Complete | anyone assigned to the job | **Written confirmation required**; records its record reference, person and date |
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

## The tracker itself: collapsed stages, bigger type, bigger marks

Decided 11 November 2026, from using it.

**Stages are collapsed by default.** Clicking a stage header expands it to show its steps
and requirements; clicking again collapses it. Eleven stages with 51 requirements all
expanded at once is a wall of text in which the thing you need is impossible to find. On
load, expand **only the stage the job is currently on** and leave the rest shut — that is
the stage someone opened the page to work on, and every other stage is reference.

The header stays informative while collapsed, because a collapsed row that says only
"Stage 4" forces you to open all eleven to find anything:

> **Stage 4 · IXIT collection** — 3 of 6 requirements · gate 4 not passed

**Type and targets, concretely** — the current build is too small to work in:

| Element | Now | Change to |
|---|---|---|
| Requirement and step body text | 13px | **15px**, line-height 1.6 |
| Stage header | 14px | **17px**, semibold |
| Requirement checkbox | ~16px | **22px**, with a ≥32px clickable row |
| Step record-reference text | 12px | **14px** |

The checkbox grows for a plain reason: people tick these while holding a device in the
other hand, and a 16px target next to a 13px label is a mis-click waiting to be an
amendment. Keep the existing `lab-*` class prefix and the `--c1-*` tokens — this is a
size and spacing change, not a new visual language.

**The confirmation goes next to the mark, not behind it.** When someone ticks a
requirement, the confirmation field opens inline underneath and the tick does not commit
until text is entered. Confirmations already recorded show under their requirement with
the name and timestamp, so the tracker reads as a record of what was done rather than a
grid of ticks.

## All QMS registers in the app

Decided 11 November 2026. **This reverses the v1 decision** that `Process_Control.xlsx`
registers are referenced by ID and kept outside the system. It is the right call — a
register in a spreadsheet beside a database is two records that will disagree — but it is
close to a doubling of v1 scope and should be sequenced, not attempted at once.

Enumerated from `Master_Document_List_QMS_CIPHER.xlsx` and the register files themselves:

**Group A — job-linked, already half-modelled, build first**

| Register | Source | Note |
|---|---|---|
| Contract Review | `Process_Control.xlsx` → Contract_Review | Gate 1's own record; `CHK-CTR-01` is its checklist |
| Job Register | `Process_Control.xlsx` → Job_Register | Largely the `jobs` table already |
| QC Activities | `Process_Control.xlsx` → QC_Activities | ISO 7.7 |
| Nonconforming Work | `Process_Control.xlsx` → NC_Work_Log | ISO 7.10 — the Closed → Open move writes here |
| Complaints | `Process_Control.xlsx` → Complaints_Log | ISO 7.9 |
| Reports Index | `Process_Control.xlsx` → Reports_Index | ISO 7.8 |

**Do not build MU_Budgets.** Measurement uncertainty was settled as not applicable to
this lab's testing, and carrying an empty register into the system imports a question an
assessor will ask. Retire the sheet rather than port it.

**Group B — lab-wide, independent of any job, build second**

| Register | Source |
|---|---|
| Competence | `RG-CMP-01` — **built** |
| Access Rights & Authorization | `RG-ACC-01` |
| Confidential Information & Legal Disclosure Log | `RG-LOG-01` |
| Impartiality Risk Register | `RG-RSK-01` |
| Personnel Role and Task Assignment | `RG-PER-TASK-01` |
| Equipment / Lab Assets inventory | `CIPHER_Lab_Assets_inventory`, `tools_to_be_calibrated` |
| Tools Scope Register | `CIPHER_IoT_Lab_Tools_Scope_Register` |
| Clause 6 Master Register | `Clause6_Master_Register` |
| Resources Control | `Resources Control.xlsx` |
| Master Document List | document control under ISO 8.3 |

**Group C — forms, not registers.** `FR-CONF-01/02`, `FR-COI-01/02`, `FR-REP-01`,
`FR-APPT-01/03` are completed instances attached to a person or a job. They become
records against an existing entity, not tables of their own.

Every register follows the rules already established: append-only audit, no hard delete,
archive with a reason, and .xlsx export so the spreadsheet remains obtainable without
being the master. The .xlsx export is what makes this change safe — nobody loses the
format they are used to, they lose only the second copy that drifts.

**Sequencing.** Group A rows mostly exist inside `jobs` and the gate records already;
surfacing them as registers is presentation plus a few columns. Group B is ten new
resources and is a project of its own. Do not start Group B before the write actions and
the three-section job list are working — a system with twelve registers and no way to run
a job is the wrong half finished.

## Not in v1

Client portal. Scheduling and resourcing — CipherOne already has a resource calendar.
Generating the report document; v1 produces the section 4 figures and the report is still
written in Word. Bulk editing. A mobile layout.
