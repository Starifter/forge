---
name: forge
description: >
  Use this skill for any feature request, bug fix, refactor, or implementation task.
  Enforces a structured UI Check → Spec → Workspace → Research → Plan → Subagent Flow → Implement → Verify → Complete pipeline.
  Trigger whenever a user says "build", "add", "implement", "create a feature", "fix this", "refactor",
  or describes any coding task — even if it sounds simple. For tiny tasks, Plan can be condensed,
  but Spec and Verify are always required.
---

# Forge

A structured, phase-gated development workflow from idea to verified, merged implementation.

---

## CRITICAL RULES — READ FIRST

1. **Never proceed to the next phase without completing the current one.** Every phase ends with a HARD GATE.
2. **Never write implementation code** during UI Check, Spec, Workspace, Research, or Plan phases.
3. **Always run `frontend-developer` agent before spec** if the task involves any UI or UX work.
4. **Research always runs** — never skipped.
5. **Always ask Sequential or Parallel** before implementing. Never assume.
6. **Always use the AskUserQuestion tool** for every question asked to the user — workspace choice, confirmations, finish options, everything. Never ask questions as plain text.

---

## Phase Overview

```
[UI Check] → Spec → Workspace → Research → Plan → Sequential or Parallel? → Implement → Verify → Complete
```

| Phase | Required | Notes |
|---|---|---|
| UI Check | If UI/UX task | `frontend-developer` agent fires before spec |
| Spec | Always | Socratic dialogue → confirmed design doc |
| Workspace | Always | User chooses worktree or inline |
| Research | Always | Codebase + external topic scan before planning |
| Plan | Always | Tasks + waves; condense for tiny tasks |
| Subagent Flow | Always | User picks sequential or parallel |
| Implement | Always | Fresh subagent per task + 2-stage review |
| Verify | Always | Tests must pass |
| Complete | Always | Summary + merge/PR options |

---

## Phase 0: UI Check (conditional)

**Before invoking spec-agent**, check whether the task involves any UI or UX work.

**UI task signals:** screen, page, view, layout, dashboard, form, modal, drawer, component, button, input, card, table, nav, menu, sidebar, design, style, theme, color, typography, spacing, animation, transition, responsive, flow, onboarding, empty state, loading state.

**If ANY of these apply:** Use the **Agent tool** to invoke the `frontend-developer` agent before spec:

```
Feature request: [user's original request]

This is a UI/UX task. Read the codebase, commit to an aesthetic direction,
and produce either a full implementation or a precise UI spec.
Confirm with the user before handing off.
```

Wait for the `frontend-developer` to return a confirmed output before invoking spec-agent. Pass the confirmed UI output to spec-agent as additional context.

**If the task has NO UI component:** skip Phase 0 and go straight to Phase 1.

---

## Phase 1: Spec

**Goal:** Understand exactly what the user wants.

Use the **Agent tool** to invoke the `spec-agent` with the user's raw request as the prompt. If a UI Check was run, also pass the confirmed Design Brief as context.

The spec-agent will:
- Run a Socratic dialogue in rounds (scope, edge cases, constraints)
- Write a structured design document
- Confirm with the user before finishing

**Do not run Spec inline. Only the `spec-agent` runs the Spec phase.**

Wait for the spec-agent to return a confirmed spec before continuing.

### ⛔ HARD GATE 1 — END OF SPEC

The `spec-agent` handles its own confirmation gate internally — it will not return until the user has confirmed the spec.

**Do not set up the Workspace until the `spec-agent` has returned a confirmed spec.**

---

## Phase 2: Workspace Setup

**Goal:** Ask the user how they want to work — isolated worktree or inline in the current codebase.

Use the AskUserQuestion tool:

```
AskUserQuestion:
  question: "How would you like to work on this?"
  options: [
    "Worktree — isolated git branch in a separate directory. Safer, main stays untouched. (Recommended)",
    "Inline — work directly in the current codebase. Faster, no setup.",
    "Other"
  ]
```

**Wait for the user's choice before continuing.**

---

### If user chooses Worktree

Check git state immediately:

```bash
git status
```

If dirty: **stop and tell the user**. Ask them to commit or stash first. Do not proceed until clean.

Once clean, **kick off worktree setup as a background agent** using the Agent tool with `run_in_background: true`:

```
Worktree setup task:

1. Create branch name from this spec title: [spec title — kebab-case, max 40 chars]
2. Run: git worktree add "../worktree-BRANCH_NAME" -b "BRANCH_NAME"
3. cd into the worktree
4. Install dependencies (npm install / pip install / bundle install / etc.)
5. Run the baseline test suite to confirm green

Report back:
- Branch name created
- Worktree path
- Baseline test result (X passing / FAILED)

If baseline tests fail, report the failures clearly.
```

**Do not wait for this agent to complete.** Record internally: **mode = worktree**, **worktree agent = running**.

Immediately proceed to Phase 3: Research in parallel.

Report to user:
```
Worktree setup running in background on a new branch.
Starting research now — I'll check worktree status before implementation begins.
```

---

### If user chooses Inline

No setup required. Check current state:

```bash
git status
```

If dirty: note the uncommitted changes and inform the user. Do not block — it is their call.

Report:
```
✅ Working inline in current codebase. Starting research now.
```

Record internally: **mode = inline**

---

### ⛔ HARD GATE 2 — END OF WORKSPACE SETUP

**Do not wait for worktree setup to complete before continuing.**

- Worktree mode: kick off background setup, immediately proceed to Research
- Inline mode: immediately proceed to Research

The worktree will be checked at Gate 4 (before implementation begins).

---

## Phase 3: Research

**Goal:** Build the context needed for accurate planning before a single line of code is written.

This phase always runs. Do not skip it. Do not research inline.

Use the **Agent tool** to invoke the `researcher` agent with this prompt:

```
Design document:
[paste the full confirmed design document from spec-agent]

Workspace: [worktree — setup running in background, research from current directory | inline — current directory]

Research the codebase and any external topics needed to plan this feature accurately.
Return a completed Research Summary.
```

Wait for the researcher to return the summary, then pass it directly to the plan-agent in Phase 4. Do not modify or summarise the researcher's output — pass it as-is.

Then proceed directly to Phase 4 — no additional gate after Research.

---

## Phase 4: Plan

**Goal:** Produce a concrete, executable plan — atomic tasks grouped into parallel-safe waves.

Use the **Agent tool** to invoke the `plan-agent` with this prompt:

```
Confirmed spec:
[paste the full confirmed spec from spec-agent]

Research summary:
[paste the full Research Summary from Phase 3]

Workspace mode: [worktree at ../worktree-<branch-name> / inline]
```

The plan-agent will:
- Write a waved task plan with exact file paths
- Ask the user to approve the plan AND choose sequential or parallel
- Not return until both are confirmed

**Do not plan inline. Only the `plan-agent` runs the Plan phase.**

Wait for the plan-agent to return an approved plan with execution mode before continuing.

### ⛔ HARD GATE 3 — END OF PLAN

**Do not begin any implementation until the `plan-agent` has returned a confirmed plan with execution mode.**

---

## Phase 5: Subagent Flow (captured in Gate 3)

The user's sequential/parallel choice is collected by the plan-agent at Gate 3. No additional step needed — proceed directly to Implement.

---

## Phase 6: Implement

**Goal:** Execute the approved plan. Path depends on execution mode chosen in Phase 4.

---

### PATH A — Sequential (user chose sequential)

You are the orchestrator. You dispatch tasks directly — no sequential-executor middleman. Process each wave in order, all tasks within a wave one at a time.

**For each wave, in order:**

#### Step 1 — Run tasks sequentially

For each task in the wave, use the **Agent tool** to invoke `task-implementer`:

```
Task: [copy task line verbatim from plan]
File: [exact file path]
Workspace: [worktree path or "inline — edit files in place"]

Current file content:
---
[full file if under 200 lines, signatures/types only if larger]
---

Coding conventions:
- [convention 1]
- [convention 2]

Implement exactly as described. Do not touch other files.
Report: what changed, deviations, assumptions.
```

Wait for each task-implementer to complete before starting the next. Record each result.

If task-implementer returns **Task Blocked**: log it as 🚫 BLOCKED, continue to next task.

#### Step 2 — Batch review the whole wave

Once ALL tasks in the wave are complete, invoke **one** `code-reviewer` agent per task — but dispatch them all simultaneously using `run_in_background: true`:

For each completed task, use the **Agent tool** with `run_in_background: true`:

```
Original task: [task line verbatim]
Target file: [file path]

Implementer's report:
[full task-implementer output for this task]

Coding conventions:
- [convention 1]
- [convention 2]

Stage 1 — Spec compliance: output match task? Only correct file touched?
Stage 2 — Code quality: bugs, violations, dead code?

Return APPROVED or NEEDS REVISION with specifics.
```

Wait for all wave reviewers to complete.

#### Step 3 — Handle NEEDS REVISION

For each NEEDS REVISION result: re-invoke `task-implementer` with original prompt + reviewer feedback, wait for result, re-invoke `code-reviewer`. Repeat up to 3 cycles → mark ⚠️ STUCK after 3 failures.

#### Step 4 — Mark wave complete, start next wave

All tasks must be ✅ or flagged before starting the next wave.

---

### PATH B — Parallel (user chose parallel)

You are the orchestrator. You dispatch tasks yourself using background agents. You do not use sequential-executor. You do not implement anything yourself.

**Waves always run in sequence. Parallelism is within a wave, not between waves.**

**For each wave, in order:**

#### Step 1 — Classify the wave

List every file path targeted by tasks in this wave. Classify each task:

- **Parallel-safe:** targets a file no other task in this wave touches → can run in background
- **Conflicted:** shares a file path with another task in this wave → must run sequentially

Classify the wave:
- **Fully parallel** → all tasks are parallel-safe → run Steps 2–6 (skip Step 7)
- **Mixed** → some parallel-safe, some conflicted → run parallel batch (Steps 2–6) then run and batch-review conflicted tasks (Step 7)
- **Fully sequential** → all tasks conflict or wave has 1 task → skip Steps 2–6, run all tasks via Step 7

Log the classification:
```
Wave [N] — [label]
Mode: Fully parallel / Mixed (X parallel, Y sequential) / Fully sequential
```

#### Step 2 — Dispatch parallel-safe tasks
*(Skip if fully sequential)*

Use the **Agent tool** with `run_in_background: true` for each parallel-safe task. Dispatch ALL before waiting.

Prompt for each:
```
Task: [task line verbatim]
File: [exact file path]
Workspace: [worktree path or "inline — edit files in place"]

Current file content:
---
[full file if under 200 lines, signatures/types only if larger]
---

Coding conventions:
- [convention 1]
- [convention 2]

Implement exactly as described. Do not touch other files.
Report: what changed, deviations, assumptions.
```

#### Step 3 — Wait for all parallel task-implementers
*(Skip if fully sequential)*

#### Step 4 — Batch-review the parallel wave
*(Skip if fully sequential)*

Once ALL parallel task-implementers in this wave have completed, dispatch one `code-reviewer` per task simultaneously using `run_in_background: true`. This is a wave-level batch — all reviewers fired at once, not one after each individual task.

Prompt for each:
```
Original task: [task line verbatim]
Target file: [file path]

Implementer's report:
[full task-implementer output]

Conventions: [list]

Stage 1 — Spec compliance: output match task? Only correct file touched?
Stage 2 — Code quality: bugs, violations, dead code?

Return APPROVED or NEEDS REVISION with specifics.
```

#### Step 5 — Wait for all wave reviewers to complete
*(Skip if fully sequential)*

Do not proceed until every reviewer for this wave has returned.

#### Step 6 — Handle NEEDS REVISION from wave batch
*(Skip if fully sequential)*

For each NEEDS REVISION: re-invoke `task-implementer` (background) with original prompt + feedback → wait → re-invoke `code-reviewer` (background) → wait → repeat up to 3 cycles → mark ⚠️ STUCK after 3 failures.

#### Step 7 — Run sequential tasks, then batch-review them
*(Always runs for conflicted tasks. Runs for entire wave if fully sequential)*

Run conflicted tasks one at a time with task-implementer. Once ALL conflicted tasks in this wave are done, dispatch their reviewers simultaneously (same batch pattern as Step 4) — do not review after each individual task.

For fully sequential waves: run all tasks in plan order, then batch-review the whole wave together.
For mixed waves: complete the parallel batch first, then run conflicted tasks, then batch-review the conflicted set.

#### Step 8 — Mark wave complete, start next wave

All tasks must be ✅ or flagged before starting the next wave.

---

### Progress log

```
## Execution Progress — [Sequential / Parallel]

### Wave 1 — [label]
- ✅ Task 1.1 — [what was done]
- ⚠️ Task 1.2 — STUCK: [issue]
- 🚫 Task 1.3 — BLOCKED: [reason]
```

---

### ⛔ HARD GATE 4 — BEFORE IMPLEMENTATION BEGINS

**If mode = worktree:** Before dispatching any task agents, check whether the background worktree setup has completed.

If the worktree background agent has returned:
- ✅ Baseline passing → proceed normally, all task agents use the worktree path
- ❌ Baseline failing → stop and report failures to the user. Ask whether to fix them first or switch to inline. Do not implement until resolved.

If the worktree background agent has NOT yet returned:
```
Waiting for worktree setup to finish before implementation starts...
```
Wait for it to complete, then apply the checks above.

**If mode = inline:** No check needed — proceed immediately.

---

### ⛔ HARD GATE 4B — END OF IMPLEMENT

Use the AskUserQuestion tool:

```
AskUserQuestion:
  question: "All tasks complete. Ready to run the full test suite?"
  options: ["Yes, run tests (Recommended)", "Not yet — I want to review first", "Other"]
```

Include the progress log in your message before calling AskUserQuestion.

**Wait for confirmation before running tests.**

---

## Phase 7: Verify

**Goal:** Confirm the full implementation works.

Run the full test suite from the workspace (worktree or current directory). If tests fail: diagnose, fix, re-run. Do not proceed until green.

```
✅ All tests passing (X passed, 0 failed)
```

---

### ⛔ HARD GATE 5 — END OF VERIFY

Use the AskUserQuestion tool. Show only options relevant to the workspace mode:

**If worktree mode:**
```
AskUserQuestion:
  question: "All tests passing. How would you like to finish?"
  options: [
    "Open a GitHub PR — push branch and open PR (requires gh CLI)",
    "Merge locally — merge into main and remove worktree",
    "Keep branch open — leave worktree as-is for further work",
    "Just clean up — remove worktree, keep branch for later",
    "Other"
  ]
```

**If inline mode:**
```
AskUserQuestion:
  question: "All tests passing. How would you like to finish?"
  options: [
    "Commit to a new branch — stage, commit, and push",
    "Keep as-is — leave changes uncommitted for now",
    "Other"
  ]
```

**Wait for the user's choice.**

---

## Phase 8: Complete

**Worktree — Option 1: GitHub PR**
```bash
cd "../worktree-<branch-name>"
git add -A && git commit -m "<commit message from spec>"
git push -u origin <branch-name>
gh pr create --title "<title>" --body "<what was built and why>"
```

**Worktree — Option 2: Merge locally**
```bash
cd "../worktree-<branch-name>"
git add -A && git commit -m "<commit message>"
git checkout main
git merge --no-ff <branch-name> -m "Merge: <feature summary>"
git worktree remove "../worktree-<branch-name>"
```

**Inline — Option 3: Commit to new branch**
```bash
git checkout -b <branch-name-from-spec>
git add -A && git commit -m "<commit message>"
git push -u origin <branch-name>
# optionally: gh pr create ...
```

**Option 4: Keep as-is**
```
Changes left uncommitted in [worktree path / current directory].
```

Deliver summary:
```
## ✅ Done

**What was built:** [1–2 sentences]

**Files changed:**
- `path/to/file` — [what changed]

**Tests:** X passed
**Branch:** <branch-name> [if applicable]
```

---

## Reference Files

- `references/planning-guide.md` — wave grouping rules and task sizing
- `references/subagent-instructions.md` — subagent prompt construction and review checklist
- `references/research-summary-template.md` — Research phase output template
