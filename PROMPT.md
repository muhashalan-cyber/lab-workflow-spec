# Prompt for the server-side Claude Code session

Paste this into the Claude Code session on the Ubuntu home-lab server. It clones the
repo itself, so there is nothing to copy across first.

---

You're building an ISO/IEC 17025 laboratory workflow system for CIPHER, a cybersecurity
testing lab pursuing SAAC accreditation. It replaces the per-job Excel tracker the lab
uses today. Once it's live the database — not the spreadsheet — is the lab's record of
its testing jobs, which is why the integrity and validation requirements in it are real
constraints rather than nice-to-haves.

Start by cloning the spec repo, then read `README.md` and follow the reading order it
gives:

```
git clone https://github.com/muhashalan-cyber/lab-workflow-spec
cd lab-workflow-spec
```

It is a specification repo, not the application. Build the application in a separate
directory and treat this one as read-only reference — if you find something wrong in it,
tell me rather than editing it, so the spec and the code keep separate histories. Don't write code until you've read
`docs/01-requirements.md`, `BUILD_BRIEF.md`, `docs/02-data-model.md` and
`docs/03-gate-rules.md`. The nine gate rules are the system's core logic — everything
else exists to serve them.

Constraints that matter:

- **Nothing in that repo has been compiled or run.** It was assembled in a sandbox with
  no packagist.org or Docker Hub access. The Dockerfile, compose file and any code are
  specifications, not working artefacts. Verify everything and rewrite what doesn't hold
  up — you can run things and the author couldn't.
- **Check the Laravel and Filament versions yourself** before committing to majors, and
  read the version note at the top of `BUILD_BRIEF.md` first. If CipherOne's codebase is
  reachable from here, match what it runs.
- **Seed from `data/`; don't invent reference data.** Those files were extracted from the
  lab's controlled documents, which you don't have and can't re-derive. The workflow is
  11 stages, 25 steps, 51 requirements, 9 gates. The method library is rev 1.3: 62
  methods, 36 of them conditional.
- **Don't answer the open questions in `docs/01-requirements.md`.** They're mine to
  decide. Build around them and tell me when one blocks you.

Work in this order: infrastructure up and healthy, schema, the audit and history layer
with database-level immutability, then the reference-data seeders. Before building all
eleven stages, do the vertical slice described in `BUILD_BRIEF.md`:

1. A job with a Responsible Engineer and a Technical Reviewer assigned.
2. Assigning the same person to both roles is refused, with a readable reason.
3. Stage 1's three steps and six requirements render and save.
4. Gate 1 refuses to pass while any condition is unmet and names the specific condition
   that's missing — not a generic "gate not met".
5. Every one of those changes appears in the audit log with its actor and timestamp, and
   an admin account cannot alter or delete an audit row.

Stop and report when that slice works, or when it turns out it can't. If it doesn't
work, the problem is structural and I need to know before more is built on it.

How to report back: I'm not a Laravel developer — I'm learning the stack alongside this
build. Tell me what works, what you couldn't verify, and what decision you need from me.
Don't present untested code as working, and don't skip a check to keep momentum. If
something in the spec is wrong, or won't work on this stack, say so rather than
implementing it badly.
