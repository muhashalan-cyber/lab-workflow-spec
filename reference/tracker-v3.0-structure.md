# Workflow Tracker v3.0 - workbook structure

The template the .xlsx export must reproduce. See docs/05-exports.md.

Generated from the workbook itself. Sheet names and column headers are verbatim;
use them when building the export so it matches the template.

## 00 How to Use

21 non-empty rows, 4 columns.

- CIPHER Hardware Security Lab — Project Workflow Tracker
- Rev 3.0 · one file per job · supersedes the ETSI TS 103 701 Assessment Workbook (42 sheets). ISO/IEC 17025 con
-  | Item | Content | Reference
-  | The document set for one job
-  | IXIT & DUT Identification Template (.docx) | DUT identification and IXIT 1–29 | ETSI steps 1 and 3
-  | ETSI Method / Test Mapping (.xlsx) Rev 1.1 | ICS declaration, applicability, method steps, acceptance criteria, verdicts | ETSI steps 2, 4, 5, 6, 8
-  | This tracker (.xlsx) | ISO/IEC 17025 stages and gates, job resources, evidence register, deviations and QC | ISO/IEC 17025 control
-  | CIPHER IoT ETSI Assessment Report (.docx) | The client deliverable | ETSI step 9 / ISO 7.8
-  | Process_Control.xlsx (lab-wide, not per job) | Contract_Review · Job_Register · QC_Activities · NC_Work_Log · Complaints_Log · Reports_Index | Referenced by ID from this tracker — never duplicated here
-  | How to run a job
-  | 1. Copy this template into the job folder | Rename to JOB-2026-XXX_Workflow_Tracker.xlsx
-  | 2. Complete sheet 01 Job Record | Job identity, roles, decision rule, and the file names of the three ETSI documents
-  | 3. Work down sheet 02 Workflow | 25 steps across 11 stages. Set Status on each step; a GATE row (orange) must read Passed before the next stage
-  | 4. Keep sheets 03–06 current as you go | Resources and item, ETSI verdict roll-up, evidence register, deviations / QC / information gaps
-  | 5. Report from sheet 04 | The counts in 04 ETSI Status are the only source for the figures and counts in report §4
-  | Conventions
-  | Yellow cells | The cells you fill in. Everything else is controlled content — change it only by revising this template under 
-  | Status values | Not started · In progress · Complete · N/A · Blocked. Gate rows use Passed / Not passed.
-  | Record Reference | The ID or file name that proves the step was done (CR-2026-XXX, FR-ITEM-01A, EV-014, a file name). A step with
-  | Evidence | Register each artefact once in 05 Evidence Register with its SHA-256, then cite the EV-XXX ID from the mapping
-  | Stages 10 and 11 | Nonconforming work and complaints — complete only if triggered; otherwise set the stage rows to N/A.

## 01 Job Record

46 non-empty rows, 3 columns.

- 01 — Job Record
- Identity, roles and controlled references for this job. Cross-references Process_Control.xlsx by ID; does not 
- Job identity | Value | ISO/IEC 17025 ref
- Job ID (JOB-2026-XXX) |  | 7.5
- Contract Review ID (CR-2026-XXX) |  | 7.1.1
- Client / Customer |  | 7.1
- Client contact |  | 7.1
- Job folder path |  | 8.4
- Start date |  | 7.1
- Planned end date |  | 7.1
- Actual end date |  | 7.1
- Job status |  | 8.4
- Classification / TLP |  | 4.2
- Device under test | Value | ISO/IEC 17025 ref
- DUT description |  | 7.4.1
- Manufacturer / Model |  | 7.4.1
- Serial number / identifier |  | 7.4.2
- Firmware version as received |  | 7.4.2
- Firmware version at end of assessment |  | 7.4.2
- Constrained device? (per ICS) |  | 7.2.1
- Scope and basis | Value | ISO/IEC 17025 ref
- Standard basis |  | 7.2.1
- Test specification |  | 7.2.1
- Assessment scope (layers in scope) |  | 7.1.3
- Assessment methodology |  | 7.2.1
- Decision rule agreed with client |  | 7.1.3 / 7.8.6
- Statement of conformity basis |  | 7.8.6
- Subcontracting used? (what / whom / client approval ref) |  | 6.6 / 7.8.2.1
- ... 18 further rows

## 02 Workflow

47 non-empty rows, 11 columns.

- 02 — Project Workflow A to Z
- 25 steps, 51 requirements, 9 gates — the same content as the PR-WKF-01 Job Runner. A GATE row (orange) must re
- Stage | Step | Activity | ISO/IEC 17025 | ETSI step | Gate / required record | Record reference | Responsible | Status | Date | Notes
- 1 Intake and contract review
- 1 | 1.1 | Register and screen the request | 7.1 · 4.1 · 4.2 · 6.6 | — | • Request logged with date received, client, contact and the client's own reference; request document saved to
- 1 | 1.2 | Impartiality, confidentiality and capability | 7.1 · 4.1 · 4.2 · 6.6 | — | • FR-COI-02 completed with prior involvement in this DUT, its firmware or the vendor explicitly checked; any r
- 1 | 1.3 | Contract, decision rule and authorization to test | 7.1 · 4.1 · 4.2 · 6.6 | — | GATE 1 — CR-2026-XXX exists, Decision = Accept, and the written Authorization to Test is filed in 00_Contract.
- 2 Job setup and readiness
- 2 | 2.1 | Open the job and the job file | 6.2 · 6.3 · 6.4 · 7.4 · 7.5 · 7.11 | — | • JOB-2026-XXX created in Process_Control > Job_Register, linked to the CR ID, with Responsible Engineer, Tech
- 2 | 2.2 | People, item, equipment and environment | 6.2 · 6.3 · 6.4 · 7.4 · 7.5 · 7.11 | — | • Each role holder Active in RG-CMP-01 with the right authority flag and the methods authorized; the Technical
- 2 | 2.3 | Create the job document set | 6.2 · 6.3 · 6.4 · 7.4 · 7.5 · 7.11 | — | GATE 2 — JOB-2026-XXX is open, the job file exists, roles are authorized, the item and equipment are recorded 
- 3 DUT identification and the ICS
- 3 | 3.1 | Identify the DUT | Annex A · 7.2 · 7.4 | Steps 1–2 | • IXIT document §1 document control complete (standard, test specification, scope, methodology, project ID, pr
- 3 | 3.2 | Obtain and challenge the ICS | Annex A · 7.2 · 7.4 | Steps 1–2 | GATE 3 — Every conditional method carries an ICS Support value, every one of the 63 methods carries an applica
- 4 IXIT completion and adequacy review
- 4 | 4.1 | Collect the IXIT | Annex B · 7.2 · 7.5 · 7.11 | Step 3 | • Required IXIT tables identified from Required IXIT Entries (R) across every method with Applicable = Y / • I
- 4 | 4.2 | Adequacy review and approval | Annex B · 7.2 · 7.5 · 7.11 | Step 3 | GATE 4 — Every IXIT entry named by an applicable method is present at entry-per-mechanism granularity, with it
- 5 Method selection and the test plan
- 5 | 5.1 | Confirm the methods and settle deviations | 7.2 · 7.7 | Steps 4–5 | • Job copy taken from the current controlled mapping revision, with columns A–F, J, K, P and R untouched / • V
- 5 | 5.2 | Plan the work and approve it | 7.2 · 7.7 | Steps 4–5 | GATE 5 — Applicability is complete for all 63 methods, verification or validation records exist for every meth
- 6 Assessment execution and evidence
- 6 | 6.1 | Baseline the DUT and assess conceptually | 7.5 · 7.7 · 6.4 | Steps 6–8 | • DUT baseline set and captured as evidence: factory reset or documented configuration, firmware version, netw
- 6 | 6.2 | Test the DUT and register the evidence | 7.5 · 7.7 · 6.4 | Steps 6–8 | • Functional assessment executed in the controlled setup using only RG-EQP-01 equipment, with the IDs actually
- 6 | 6.3 | Set the verdicts and run quality control | 7.5 · 7.7 · 6.4 | Steps 6–8 | GATE 6 — Every applicable method has a tester verdict, every verdict names at least one registered Evidence ID
- 7 Technical review
- 7 | 7.1 | Confirm independence and completeness | 7.5 · 7.7 · 6.2 · 7.8.7 | Step 8 | • Reviewer did not perform the work under review and holds Can Perform Technical Review = Yes in RG-CMP-01 / •
- 7 | 7.2 | Check traceability and correctness, then sign | 7.5 · 7.7 · 6.2 · 7.8.7 | Step 8 | GATE 7 — Every tested method carries a reviewer verdict and a Final Verdict, the tracker counts reconcile, and
- 8 Reporting
- ... 19 further rows

## 03 Resources & Item

22 non-empty rows, 11 columns.

- 03 — Job Resources, Environment and Test Item
- ISO/IEC 17025 6.2, 6.3, 6.4 and 7.4. Calibration must remain valid through the planned job end date; record th
- A — Equipment and tools used on this job
- Asset ID | Equipment / tool | Serial / version | Use on this job | Calibration or verification required? | Calibration certificate ref | Calibration valid to | Valid through job end? | Out of tolerance? impact assessment | Checked by | Date
- B — Environmental conditions
- Check | Requirement (PR-ENV-01) | Recorded value / observation | Conforms? | Record reference |  |  |  |  | Checked by | Date
- Temperature | Within the range stated in PR-ENV-01
- Humidity | Within the range stated in PR-ENV-01
- Power / supply | Stable supply appropriate to the DUT
- RF / interference | No condition that could affect results
- Physical access / separation | Work area controlled and incompatible activities separated
- Network isolation | Test network isolated as required by the method
- C — Test item receipt, handling and return
- Item | Record | Value | Reference / notes |  |  |  |  |  | By | Date
- Receipt | Date received, received by, condition on receipt, abnormalities noted
- Identification | Unique job identification applied to the item and retained throughout
- Deviation from specified condition | Any departure from the specified or standard condition, and the client consultation
- Storage and handling | Storage conditions and handling precautions applied to avoid deterioration or damage
- Configuration changes | Firmware, settings or hardware changes made during the assessment, and the restoration
- Return or disposal | Date, method, recipient and condition on return; client authorization for any disposal
- D — Personnel competence for this job
- Name | Role on this job | Authorized in RG-CMP-01? | Competence basis / training ref |  |  |  |  |  | Confirmed by | Date

## 04 ETSI Status

35 non-empty rows, 9 columns.

- 04 — ETSI Verdict Roll-up
- The single source for the counts and figures in report §4. Enter the counts per provision group from the Metho
- A — ETSI job documents
- Document | File name | Version / Rev | Date | Approved by | Status
- IXIT & DUT Identification
- Method / Test Mapping
- Assessment Report
- B — Verdicts by provision group
- Clause | Provision group | Methods in library | Applicable (Y) | PASS | FAIL | INCONCLUSIVE | N/A | NOT TESTED
- 5.1 | No universal default passwords | 5
- 5.2 | Implement a means to manage reports of vulnerabilities | 3
- 5.3 | Keep software updated | 16
- 5.4 | Securely store sensitive security parameters | 4
- 5.5 | Communicate securely | 8
- 5.6 | Minimize exposed attack surfaces | 9
- 5.7 | Ensure software integrity | 2
- 5.8 | Ensure that personal data is secure | 3
- 5.9 | Make systems resilient to outages | 3
- 5.10 | Examine system telemetry data | 1
- 5.11 | Make it easy for users to delete user data | 4
- 5.12 | Make installation and maintenance of devices easy | 3
- 5.13 | Validate input data | 1
- — | SCA / FI screening (scheme-defined) | 1
- Total |  | 63 | 0 | 0 | 0 | 0 | 0 | 0
- C — Report placeholder values (report §4 must use these)
- Placeholder | Value | Source
- {{N_METHODS_EVALUATED}} | 0 | Applicable (Y) total
- {{N_PASS}} | 0 | PASS total
- ... 7 further rows

## 05 Evidence Register

4 non-empty rows, 13 columns.

- 05 — Evidence Register
- ISO/IEC 17025 7.5.1 and 7.11.3. Register each artefact once, with its hash. Cite the EV ID from the mapping fi
- Evidence ID | Type | Description | File name / location | SHA-256 | Date collected | Collected by | Related method ID(s) | Related IXIT entry ID(s) | Confidentiality | Review status | Retention / disposal | Notes
- EV-001 | Screenshot | Example row — delete before use: web UI login page showing the credential change dialogue after first-use enfo | /evidence/EV-001_login_ui.png | e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 |  | M. Alshalan | CLT-701-PWD-04 | AUTH-01 | TLP: AMBER | Accepted | 10 years

## 06 Deviations, QC & Gaps

10 non-empty rows, 8 columns.

- 06 — Deviations, Quality Control, Information Gaps and Cross-references
- ISO/IEC 17025 7.2.2.2 (deviations), 7.7 (quality control), 7.2.1 (IXIT adequacy and information gaps), 7.9 / 7
- A — Authorized method deviations (authorize before testing)
- Ref | Method ID | Deviation from the method | Technical justification | Client informed / agreed | Authorized by | Date | Effect on the verdict
- B — Quality control activities for this job (plan, then record the result)
- QC ID | Method / test | Type of QC | Acceptance criterion | Result | Departure? action taken | Performed by | Date
- C — IXIT adequacy observations and information gaps
- Ref | IXIT entry / method ID | Observation — what is missing, vague or inconsistent | Request issued to supplier | Date raised | Response received | Resolved? | Effect on the verdict (e.g. INCONCLUSIVE)
- D — Nonconforming work and complaints raised on this job
- ID | Type | Description | Immediate action and decision on affected work | Client informed | Corrective action ref | Closed | Logged in Process_Control? (NC_Work_Log / Complaints_Log)

## 07 Lists

10 non-empty rows, 9 columns.

- 07 — Controlled Lists
- Reference values used by the drop-downs in this tracker. Keep aligned with the Method / Test Mapping and the r
- Workflow status | Verdict | Evidence class (report) | ICS support | Yes / No | Review status | TLP | Severity | Job status
- Not started | PASS | Confirmed by evidence | Y | Yes | Pending | TLP: RED | Critical | Open
- In progress | FAIL | Declared by the manufacturer / supplier | N | No | Accepted | TLP: AMBER+STRICT | High | On hold
- Complete | INCONCLUSIVE | Observed by the laboratory | N-A | N/A | Rejected | TLP: AMBER | Medium | Testing
- Passed | N-A | Inferred but not confirmed |  |  |  | TLP: GREEN | Low | In review
- Not passed | NOT TESTED | Unknown / not tested |  |  |  | TLP: CLEAR | Informational | Reported
- N/A |  |  |  |  |  |  |  | Done
- Blocked
