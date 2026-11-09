# Exports

Exports are generated copies, never the record. Every export carries a footer naming the
job, the workflow revision it ran under, who generated it, the UTC timestamp and the
job's TLP marking, so a printed page can be traced back and its currency judged.

Generate in a queue worker, not the web request. Log each generation: who exported what,
when.

| Export | Format | Purpose |
|---|---|---|
| Workflow tracker | .xlsx reproducing sheets 01–07 | Filing a job, handing a familiar artefact to an assessor |
| Job record | Markdown | Reading, diffing, version control |
| Report section 4 figures | .xlsx or clipboard | The counts the Word report needs, from the roll-up so they cannot drift |
| Evidence register | .xlsx / .csv | Cross-checking against the job folder |
| Audit trail | .csv, filtered by job and date | Assessment, and complaint investigation |
| Job register | .xlsx | The lab-wide view `Process_Control.xlsx` holds today |

## The tracker export must match the v3.0 template

This is a validation test case. If the export and the template disagree, the export is
wrong. Sheet by sheet:

**00 How to Use** — static guidance. Reproduce the document-set table and the
conventions block.

**01 Job Record** — five labelled blocks down column A with values in column B and the
ISO reference in column C: Job identity (11 fields), Device under test (6), Scope and
basis (7), Roles (5), Controlled job documents (6), Sign-off (4 — the gate 5, 7, 8 and 9
sign-offs with name and date).

**02 Workflow** — the 25 steps across 11 stages, columns: Stage, Step, Activity,
ISO/IEC 17025, ETSI step, Gate / required record, Record reference, Responsible, Status,
Date, Notes. Stage header rows separate the groups. A GATE row is highlighted and reads
Passed / Not passed. The progress block at the foot counts: steps total, complete or
passed, N/A, blocked or not passed, open, gates passed, gates total.

**03 Resources & Item** — four blocks: A equipment (11 columns, asset ID through checked
by and date), B environmental conditions (6 fixed checks), C test item receipt, handling
and return (6 fixed records), D personnel competence for this job.

**04 ETSI Status** — A job documents; B verdicts by provision group, one row per the 14
clause groups with methods in library, applicable, PASS, FAIL, INCONCLUSIVE, N/A,
NOT TESTED, and a total row; C the report placeholder values
(`{{N_METHODS_EVALUATED}}`, `{{N_PASS}}`, `{{N_FAIL}}`, `{{N_INCONCLUSIVE}}`, `{{N_NA}}`,
`{{N_NOT_TESTED}}`, `{{N_FINDINGS}}`, `{{AFFECTED_DOMAINS}}`) and the reconciliation
check line.

**05 Evidence Register** — one row per evidence item: Evidence ID, Type, Description,
File name / location, SHA-256, Date collected, Collected by, Related method ID(s),
Related IXIT entry ID(s), Confidentiality, Review status, Retention / disposal, Notes.

**06 Deviations, QC & Gaps** — four blocks: A authorized method deviations, B quality
control activities, C IXIT adequacy observations and information gaps, D nonconforming
work and complaints raised on this job.

**07 Lists** — the controlled values from `data/controlled-lists.json`, as the columns
the template uses.

Yellow fill marks the cells a person fills in the template. In an export every value is
already filled, so use the fill to mark provenance instead — or drop it and say so in
the footer. Decide once and record the choice.
