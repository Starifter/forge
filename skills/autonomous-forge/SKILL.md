---
name: autonomous-forge
description: >
  Semi-autonomous forge run. You stay in the loop for the judgment calls — Spec and
  Plan ask questions and require your approval, exactly like interactive forge. Once
  you approve the plan, Implement and Verify run UNATTENDED in an isolated worktree
  with no further questions, then stop with a green branch committed locally and a
  report. ONLY use this when explicitly invoked via the /forge:auto command or when
  the user explicitly asks for a background/unattended implementation run. For a fully
  interactive run, use the `forge` skill instead.
---

# Autonomous Forge

A semi-autonomous run. You're in the loop for the parts that need judgment — **Spec and Plan are fully interactive** — and then the tedious part runs by itself: **once you approve the plan, Implement and Verify run unattended** and report back. It stops after Verify with the work committed locally in an isolated worktree for you to review and ship.

---

## CORE CONTRACT — READ FIRST

1. **Interactive up front.** Spec and Plan ask questions and require explicit approval, exactly like interactive forge. Use `AskUserQuestion` for every question through plan approval.
2. **Handoff at plan approval.** The moment the user approves the plan and picks an execution mode is the handoff. **After that point, ask nothing** — Implement and Verify run with zero further interaction until the final report. If a decision comes up mid-execution, make the safest reasonable choice, record it as an assumption, and continue — or halt and report (see Halt protocol). Never silently skip work or fake a result.
3. **Isolated worktree, always.** Execution happens in a dedicated git worktree on a new branch, so you can keep working in your tree while it runs. Not configurable in this mode.
4. **Stop after Verify.** Do not push, open a PR, or merge. End with the work committed locally in the worktree + a report. Shipping is your call.
5. **Resumable.** All state goes to `.forge/[feature-name]/`, so a halted run can be picked up by `/forge`.

---

## Settings

Read `pluginConfigs["forge"].options` at the start:

| Setting | Default | Effect in this mode |
|---|---|---|
| `tdd_mode` | `false` | If `true`: use `tdd-task-implementer` instead of `task-implementer` |
| `auto_max_fix_attempts` | `3` | During unattended execution, retry budget for fixing a failing task or red test suite before halting |

Execution mode (sequential/parallel) is chosen by the user at plan approval — there is no separate setting. Research always runs. Artifacts are always kept (you review them after).

---

## Pipeline

```
INTERACTIVE:  Init → [UI Check] → Spec → Worktree → Research → Plan (approve + mode)
─────────────────────────── handoff ───────────────────────────
UNATTENDED:   Implement → Verify → Stop + Report
```

### Phase A — Init

Derive a feature-name (lowercase, hyphenated, ≤40 chars). Create the session dir + `session.md`:

```bash
FEATURE_NAME="[derived-feature-name]"
mkdir -p ".forge/${FEATURE_NAME}"
cat > ".forge/${FEATURE_NAME}/session.md" << 'EOF'
# Forge Session (SEMI-AUTONOMOUS)

## Feature
[feature name]

## Mode
semi-autonomous — interactive Spec + Plan, then unattended Implement + Verify

## Status
- [ ] Spec
- [ ] Worktree
- [ ] Research
- [ ] Plan
- [ ] Implement
- [ ] Verify
- [ ] Report

## Branch
[set in Worktree phase]
EOF
```

Every agent you invoke gets `Feature folder: .forge/[feature-name]/` as the first line of its prompt. Tick each box as the phase completes.

### Phase B — UI Check (conditional, interactive)

If the task involves UI/UX, invoke the `frontend-developer` agent (non-interactive — it drafts `ui-spec.md`), then **confirm the direction with the user** via AskUserQuestion (you're still in the loop here). Fold the confirmed `ui-spec.md` into the spec.

### Phase C — Spec (interactive)

Run the full Spec dialogue **inline**, following `../forge/references/spec-dialogue.md`: ask in rounds (scope → behaviour/edge cases → constraints → validation) with AskUserQuestion, write `spec.md`, and confirm it with the user. Do not skip the dialogue — this is where the user shapes what gets built. Tick `Spec` once confirmed.

### Phase D — Worktree

Always worktree (so unattended execution stays isolated). Check the tree is clean:

```bash
git status --porcelain
```

- **Dirty** → tell the user and stop; ask them to commit or stash first. Do not stash unattended.
- **Clean** → create the worktree:

```bash
git worktree add "../worktree-[feature-name]" -b "[feature-name]"
```

Invoke `dependency-installer` (pass the worktree path) and run the baseline suite. Baseline red → tell the user and stop (can't attribute later failures). Record branch + worktree path in `session.md`, tick `Worktree`.

### Phase E — Research

Invoke the `researcher` agent (reads `spec.md`, writes `research.md`). Tick `Research`.

### Phase F — Plan (interactive)

Invoke the `plan-agent` (non-interactive — drafts `plan.md`, returns a summary). Then **you run approval interactively**, exactly like interactive forge Phase 4:

1. Present the plan summary and ask approval via AskUserQuestion. If changes: re-invoke `plan-agent` with feedback, re-ask. Don't proceed until approved.
2. Ask execution mode (Sequential / Parallel) via AskUserQuestion. Record it at the top of `plan.md` and in `session.md`.

Tick `Plan`.

### ⛔ HANDOFF — last interaction

Once the plan is approved and the mode chosen, tell the user clearly:

```
Plan approved. Going heads-down now — I'll implement and verify unattended in the
worktree and report back when it's green (or halt with a report if something blocks).
```

**From here on, ask nothing.**

### Phase G — Implement (unattended)

Execute the waves like interactive forge's Phase 6 — **PATH A** if sequential, **PATH B** (file-conflict classification) if parallel — using `task-implementer` (or `tdd-task-implementer` if `tdd_mode`) + the 2-stage `code-reviewer` batch per wave. **No Gate 4B "ready to run tests?" question** — proceed straight to Verify.

Failure policy (auto-retry, then stop):
- `NEEDS REVISION` → re-invoke the implementer with the feedback; cap at `auto_max_fix_attempts` cycles per task.
- A task still failing after the cap, or a `Task Blocked` report → **HALT** and report. Never silently skip.

Maintain the one-line-per-task progress log; drop raw agent outputs at the end. Tick `Implement`.

### Phase H — Verify (unattended)

Run the full test suite in the worktree.
- **Green** → tick `Verify`, go to Stop + Report.
- **Red** → diagnose, fix, re-run, up to `auto_max_fix_attempts`. Still red → **HALT** and report with the failing output.

### Phase I — Stop + Report (terminal)

Commit the work **locally in the worktree** — no push, no PR, no merge:

```bash
cd "../worktree-[feature-name]"
git add -A
git commit -m "[feature]: [one-line summary from spec]"
```

Write `complete.md` and deliver a concise final message:

```bash
cat > ".forge/[feature-name]/complete.md" << 'EOF'
# Run complete: [Feature Name]

## Status
✅ Verified green — committed locally, NOT shipped (review before merge/PR)

## What was built
[1–2 sentences]

## Files changed
- `path` — [what changed]

## Tests
[X passed]

## Branch / worktree
[branch] @ ../worktree-[feature-name]

## Assumptions made during execution
- [any decision made without you after the handoff — or "none"]

## To ship
Review the worktree, then: `git checkout main && git merge --no-ff [branch]`
(or open a PR from the branch).
EOF
```

Tick `Report` and stop.

---

## Halt protocol

If an unattended phase (Implement / Verify) says **HALT**, stop and write `.forge/[feature-name]/auto-report.md`:

```bash
cat > ".forge/[feature-name]/auto-report.md" << 'EOF'
# Run HALTED during unattended execution: [Feature Name]

## Stopped at
[phase — e.g. "Implement / Task 2.3", "Verify"]

## Why
[exact reason — failing test output, blocker report, etc.]

## Done so far
[the progress log — which tasks completed]

## What's needed to proceed
[the specific thing a human must decide or fix]

## Resume
State is in .forge/[feature-name]/. Resume interactively with /forge to take over.
EOF
```

Then deliver a short, honest message: where it stopped and why. Never dress a halt up as success.

---

## Reference files

- `../forge/references/spec-dialogue.md` — the interactive Spec dialogue (run it in full)
- `../forge/references/planning-guide.md` — wave grouping + task sizing
- `../forge/references/subagent-instructions.md` — subagent prompt construction + review checklist

Uses forge's agents (`researcher`, `plan-agent`, `frontend-developer`, `task-implementer`, `tdd-task-implementer`, `code-reviewer`, `dependency-installer`) — all non-interactive; the orchestrator owns every question through plan approval.
