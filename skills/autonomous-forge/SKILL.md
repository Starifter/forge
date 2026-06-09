---
name: autonomous-forge
description: >
  Non-interactive, unattended version of the forge pipeline for background runs.
  Runs Spec → Research → Plan → Implement → Verify with NO user interaction — every
  gate is replaced by an automated default — then stops with a green, ready-to-ship
  branch committed locally in an isolated worktree. ONLY use this when explicitly
  invoked via the /forge:auto command or when the user explicitly asks for an
  unattended/background/automated forge run. For normal interactive work, use the
  `forge` skill instead.
---

# Autonomous Forge

An unattended run of the forge pipeline. It makes every decision itself and **never asks the user anything** — so it can be left to run in the background. It stops after Verify with the work committed locally in an isolated worktree for you to review and ship.

---

## CORE CONTRACT — READ FIRST

1. **Zero interaction.** Never call `AskUserQuestion`. Every interactive gate in normal forge is replaced by an automated default below. If you ever feel you need to ask the user, instead **make the safest reasonable decision, record it as an assumption, and continue** — or halt and report (see Halt protocol).
2. **Isolated worktree, always.** Never work in the user's current tree. All implementation happens in a dedicated git worktree on a new branch.
3. **Stop after Verify.** Do not push, open a PR, or merge. End with the work committed locally in the worktree + a report. Shipping is the user's call.
4. **Fail loud, never fake.** Never fabricate test passes, skip tasks silently, or report success that didn't happen. If you can't complete something, halt and report exactly where and why.
5. **Resumable.** Write all state to `.forge/[feature-name]/` exactly like interactive forge, so a halted run can be picked up by `/forge` or `/forge:plan` etc.

---

## Settings

Read `pluginConfigs["forge"].options` at the start. Relevant to autonomous runs:

| Setting | Default | Effect in auto mode |
|---|---|---|
| `tdd_mode` | `false` | If `true`: use `tdd-task-implementer` instead of `task-implementer` |
| `auto_execution_mode` | `"sequential"` | `"sequential"` or `"parallel"` — how waves execute. Sequential isolates failures; parallel is faster |
| `auto_max_fix_attempts` | `3` | Retry budget for fixing a failing task or a red test suite before halting |

Notes:
- **Research always runs** in auto mode regardless of `auto_research` — there is no user to confirm a skip.
- **Artifacts are always kept** in auto mode regardless of `auto_clean` — the `.forge/[feature-name]/` files are how you review the run.

---

## Input

The task description is passed in by the `/forge:auto` command (everything after the command). The richer it is, the better the result — auto mode cannot ask follow-ups, so it fills gaps with recorded assumptions. If the task is empty or a single vague word, halt immediately and report that a task description is required.

---

## Pipeline

```
Init → [UI Check] → Auto-Spec → Worktree → Research → Plan → Implement → Verify → Stop+Report
```

### Phase A — Init

Derive a feature-name from the task: lowercase, hyphenated, max 40 chars. Create the session directory and `session.md`:

```bash
FEATURE_NAME="[derived-feature-name]"
mkdir -p ".forge/${FEATURE_NAME}"
cat > ".forge/${FEATURE_NAME}/session.md" << 'EOF'
# Forge Session (AUTONOMOUS)

## Feature
[feature name]

## Mode
autonomous — unattended, stops after Verify

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

Every agent you invoke gets `Feature folder: .forge/[feature-name]/` as the first line of its prompt. Tick each box in `session.md` as the phase completes.

### Phase B — UI Check (conditional)

If the task involves UI/UX (screen, page, component, form, modal, layout, dashboard, nav, style, theme, etc.), invoke the `frontend-developer` agent (it is non-interactive — it commits to a direction itself):

```
Feature folder: .forge/[feature-name]/

Feature request: [task]

UI/UX task. Read the codebase, commit to the strongest aesthetic direction, and
write a UI spec (or implementation) to ui-spec.md. Run non-interactively; record
any visual assumptions in your return message.
```

Fold its `ui-spec.md` direction into the spec. **Do not** confirm — auto mode accepts it and records it as an assumption.

### Phase C — Auto-Spec

There is no dialogue. Write `spec.md` yourself from the task text (and `ui-spec.md` if present), using the template in `references/spec-dialogue.md`. Where the task is silent, choose the most reasonable interpretation and list every such choice under an explicit `## Assumptions (auto-derived)` section. Do not confirm — proceed.

Tick `Spec`.

### Phase D — Worktree

Auto mode is always worktree. First check the tree is clean:

```bash
git status --porcelain
```

- **Dirty** → **HALT** (see Halt protocol). Do not stash or discard the user's uncommitted work unattended.
- **Clean** → create the worktree on a new branch derived from the feature name:

```bash
git worktree add "../worktree-[feature-name]" -b "[feature-name]"
```

Then invoke the `dependency-installer` agent (pass the worktree path) and run the **baseline** test suite in the worktree.

- Baseline **red** → **HALT**. A pre-existing red baseline makes it impossible to attribute later failures.
- Baseline **green** (or no tests) → record the branch + worktree path in `session.md`, tick `Worktree`, continue.

All subsequent file work happens inside the worktree.

### Phase E — Research

Always run. Invoke the `researcher` agent:

```
Feature folder: .forge/[feature-name]/

Read .forge/[feature-name]/spec.md, research the codebase and any external topics
needed to plan accurately, and write .forge/[feature-name]/research.md.
```

Tick `Research`.

### Phase F — Plan

Invoke the `plan-agent` (non-interactive — it drafts and returns a summary):

```
Feature folder: .forge/[feature-name]/

Read spec.md and research.md, produce a waved implementation plan, write it to
plan.md, and return a summary. Workspace: worktree at ../worktree-[feature-name]
```

**Auto-approve** the plan (no AskUserQuestion). Set the execution mode from `auto_execution_mode` and record it at the top of `plan.md` (`## Execution mode: [Sequential / Parallel]`). Tick `Plan`.

### Phase G — Implement

Execute the waves exactly like interactive forge's Phase 6 — **PATH A** if `auto_execution_mode` is `sequential`, **PATH B** (file-conflict classification → parallel-safe vs conflicted) if `parallel` — using `task-implementer` (or `tdd-task-implementer` if `tdd_mode`) per task, then the 2-stage `code-reviewer` batch per wave. All agents already run non-interactively.

Maintain the one-line-per-task progress log in context. **Failure policy (auto-retry, then stop):**
- `NEEDS REVISION` from review → re-invoke the implementer with the feedback. This is the auto-retry. Cap at `auto_max_fix_attempts` cycles per task.
- A task still failing after the cap, or a `Task Blocked` report → **HALT** and report (do not silently skip).
- Waves run in sequence; never start the next wave until the current one is fully resolved.

At Gate 4B-equivalent: drop raw agent outputs, keep the progress log, tick `Implement`.

### Phase H — Verify

Run the full test suite in the worktree.

- **Green** → tick `Verify`, go to Stop+Report.
- **Red** → diagnose, fix, re-run. Repeat up to `auto_max_fix_attempts` times. Still red after the budget → **HALT** and report with the failing output.

### Phase I — Stop + Report (terminal)

Commit the work **locally in the worktree** — no push, no PR, no merge:

```bash
cd "../worktree-[feature-name]"
git add -A
git commit -m "[feature]: [one-line summary from spec]"
```

Write `complete.md` and the final report, tick `Report`, and stop.

```bash
cat > ".forge/[feature-name]/complete.md" << 'EOF'
# Autonomous run complete: [Feature Name]

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

## Assumptions made (auto-derived)
- [every decision auto mode made without you]

## To ship
Review the worktree, then: `git checkout main && git merge --no-ff [branch]`
(or open a PR from the branch).
EOF
```

Deliver a concise final message mirroring `complete.md`.

---

## Halt protocol

Whenever a phase says **HALT**, stop the run and write `.forge/[feature-name]/auto-report.md`:

```bash
cat > ".forge/[feature-name]/auto-report.md" << 'EOF'
# Autonomous run HALTED: [Feature Name]

## Stopped at
[phase — e.g. "Verify", "Implement / Task 2.3", "Worktree (dirty tree)"]

## Why
[exact reason — failing test output, blocker report, dirty tree, etc.]

## Done so far
[the progress log — which phases/tasks completed]

## What's needed to proceed
[the specific thing a human must decide or fix]

## Resume
State is in .forge/[feature-name]/. Resume interactively with /forge (or /forge:plan
/ /forge:implement) to take over from here.
EOF
```

Then deliver a short, honest final message: where it stopped, why, and that a report was written. Never dress a halt up as success.

---

## Reference files

Reuses interactive forge's references:
- `../forge/references/spec-dialogue.md` — spec.md template (write it directly; skip the dialogue)
- `../forge/references/planning-guide.md` — wave grouping + task sizing
- `../forge/references/subagent-instructions.md` — subagent prompt construction + review checklist

And forge's agents (`researcher`, `plan-agent`, `frontend-developer`, `task-implementer`, `tdd-task-implementer`, `code-reviewer`, `dependency-installer`) — all non-interactive.
