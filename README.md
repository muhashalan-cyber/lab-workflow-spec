# CIPHER Lab Workflow System — build handover package

**For the Claude Code session running on the Ubuntu home-lab server.**

This package contains everything needed to build the system that replaces CIPHER's
per-job workflow tracker spreadsheet. It was assembled in a sandbox that could not
reach packagist.org or Docker Hub, so no dependency was installed and **no code here
has been compiled or run**. Treat the source as a specification that happens to be
executable, and verify everything as you build.

## Read in this order

| # | File | What it gives you |
|---|------|-------------------|
| 1 | `docs/01-requirements.md` | What the system is and the four settled decisions. Read first — everything else assumes it |
| 2 | `BUILD_BRIEF.md` | The build order, the vertical slice to do first, and the commands |
| 3 | `docs/02-data-model.md` | Every table, column and constraint |
| 4 | `docs/03-gate-rules.md` | The nine gates as machine-checkable rules. This is the system's core logic |
| 5 | `docs/04-roles-and-access.md` | Roles, the permission matrix, and the separation-of-duties rules |
| 6 | `docs/05-exports.md` | The tracker .xlsx layout to reproduce, sheet by sheet |
| 7 | `docs/06-validation-plan.md` | The ISO 7.11.2 test cases. Write these as the test suite |

## What is in `data/`

Reference data extracted from CIPHER's controlled documents. You do not have those
source files, and they cannot be re-derived — seed from these.

- `workflow.json` — PR-WKF-01 rev 3.0: 11 stages, 25 steps, 51 requirements, 9 gates,
  with each stage's purpose, ISO references and controlled documents
- `methods.json` — all 63 ETSI methods from Method / Test Mapping rev 1.2, with
  conditions, acceptance criteria, steps and evidence, tools and required IXIT entries.
  Each carries a normalised `conditional` boolean: 37 of the 63 carry a real condition
  and need an ICS value before gate 3 can pass; the other 26 read `N/A` in the source
  sheet, meaning unconditional, and have `conditions` nulled
- `provision-groups.json` — the 14 clause groups and how many methods sit in each
- `controlled-lists.json` — the controlled drop-down values from tracker sheet 07

## What is in `ui/`

A working HTML prototype of the job tracker page, built against CipherOne's own
compiled stylesheet. Use it as the visual target for the Filament page — the stage
accordion, the gate boxes and the step/requirement structure are all settled there.

## What is in `reference/`

The source artefacts the data was extracted from, for checking. `job-runner-rev3.0.html`
is the interactive runner the workflow JSON came from; the two `*-structure.md` files
describe the v3.0 tracker workbook and the mapping workbook sheet by sheet.

## Four decisions already settled — do not revisit without asking

1. **The database is the record.** Markdown and Excel are exports generated from it,
   never the other way round. This triggers ISO/IEC 17025 7.11.2 validation before
   first production use.
2. **Laravel + Filament**, to match CipherOne so the module can be folded into it later.
   See the version note in `BUILD_BRIEF.md` before choosing majors.
3. **Local accounts with TOTP**, built so OIDC can be added later. No dependency on
   CIPHER's directory.
4. **Evidence is registered, not stored.** The system holds metadata, the path and the
   SHA-256 value. Files stay in the job folder. The system cannot verify a hash.

## Open questions that are not yours to answer

These sit with Muhannad and are recorded in `docs/01-requirements.md`. Build around
them; do not invent answers:

- Whether the home lab is the permanent host or the build-and-validate environment
- The retention period from `PR-REC-CTRL-01`
- Who the deputy or external Technical Reviewer will be (jobs will block at gate 5
  until such a person exists — that is intended behaviour, not a bug)
- Whether Mapping rev 1.1 or rev 1.2 is the controlled revision
