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
- **ETSI verdict roll-up** — the 14 provision groups, 63 methods, with the
  reconciliation line.

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
