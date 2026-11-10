# UI notes

`prototype.html` is a working prototype of the job workflow tracker, built against
CipherOne's own compiled Filament stylesheet. It is the visual target for the Filament
page — the structure is settled, so do not redesign it.

It will not render standalone from this folder: it references CipherOne's compiled
`panels.css` and its icon set, which are not included here (892 KB of compiled CSS
belonging to CipherOne). Take it as markup and structure, not as a runnable page.
`assets/lab.css` is the only stylesheet written for this feature and it is included in
full — it builds on CipherOne's `--c1-*` design tokens and adds nothing of its own
beyond the tracker components.

## What the prototype establishes

- **Navigation.** A nested expandable item, *IoT Security Lab*, inside the Penetration
  Testing group, using Filament's existing `fi-sidebar-sub-group-items` pattern. Its
  children: Lab Jobs, Workflow Tracker, Method / Test Mapping, IXIT Documents, Evidence
  Register, Deviations QC & Gaps, Reports, Nonconformities & Complaints.
- **Job record strip** — the sheet 01 fields as a label/value grid.
- **Job document set** — the four per-job documents plus `Process_Control.xlsx`
  referenced by ID.
- **Stage rail** — nine sequential stages with done / current / pending states and a
  gates-passed count.
- **Stage accordions** — each carrying purpose, controlled documents, its numbered steps
  with guidance text, the per-requirement checklist, and the gate box at the foot
  (green passed, amber not passed) with the gate statement in full.
- **Exception tracks** — stages 10 and 11 pulled out under "Triggered at any time",
  not in the sequence.
- **ETSI verdict roll-up** — the provision groups (13 in library rev 1.3), 62 methods, with the
  reconciliation line.

## The gate box: three boxes, not one

**The prototype does not cover this.** It renders only the gate statement and a
passed/not-passed pill — no named reasons, no notion of an attestation at all, despite
the note below saying the gate box is where `blocked_reasons` go. "Follow the prototype"
and "never render an attestation as a check" therefore do not conflict; the prototype is
simply silent here. This section is the settled design, built and reviewed 11 Nov 2026.

The gate box splits into three, in this order:

| Box | Shows | Treatment |
|---|---|---|
| **Checked by the system** | every rule, satisfied or failed, each naming its specific condition and carrying its rule id | green and red rule-id chips; *n* of *m* conditions met |
| **Could not be judged** | unevaluable rules | grey, neither passed nor failed, with "The gate cannot pass while this is true" |
| **Attested by a person** | each attestation, its signer and the time | blue, never green; a quill, never a tick; "The system cannot verify these" |

Three rules that carry the whole distinction:

1. **No checkmark ever appears in an attestation.** A tick reads as verified. The
   machine-rule list uses coloured rule-id chips rather than ticks, so a tick appears
   nowhere on the card — which is what makes the rule hold.
2. **Attestations are blue, not green.** Green reads as verified.
3. **A signed attestation always shows the person and the time**, because the person is
   the evidence. A bare mark would imply the system checked it.

Wording that is load-bearing and should not be softened: "The system cannot verify
these", "Asserted by *name* on *date* — not verified by the system", and, unsigned,
"Not yet attested — needs a named person to assert it".

### Two refinements from the first review

- **Make "not verified by the system" carry the blue accent in the signed state**, as its
  own element rather than grey trailing text at the end of the attribution line. It is the
  most important phrase on a passed gate card and is currently set in the quietest type on
  it. Note the asymmetry worth correcting: the *unsigned* state shouts in amber while the
  *signed* state whispers in grey — and the signed state is the risky one, because that is
  where an assertion sits among satisfied checks.
- **Give the attestation box a count** — "1 of 1 signed" — matching "8 of 8 conditions
  met". The parallel makes it visible at a glance that a passed gate rests partly on
  assertions.

## Building it in Filament

The job list is an ordinary Filament resource table. The tracker is a **custom page**,
not a resource — it is one job's state across several tables, with actions on it.
The stage accordion maps to a Livewire component per stage; the gate box is where the
gate evaluator's `blocked_reasons` are rendered, each as a link to the record that needs
fixing.

The demo job in the prototype is deliberately parked on gate 5 with no Technical
Reviewer assigned. Keep an equivalent fixture in the test suite — a blocked gate is the
state that matters most and the easiest to get wrong.

`lab-*` class names follow CipherOne's convention of prefixing feature-specific styles
(their SOC pages use `soc-*`). Keep that convention.
