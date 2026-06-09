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
6. **Always use the AskUserQuestion tool** for every question asked to the user — workspace choice, spec dialogue, plan approval, execution mode, UI confirmation, finish options, everything. Never ask questions as plain text.
7. **After all waves complete** (at Gate 4B), discard all raw task-implementer and code-reviewer output. Keep only the one-line-per-task progress log in context — it carries forward into Verify and Complete. Per-task completion is also persisted on disk by the `[x]` checkboxes in `plan.md`.
8. **Subagents are non-interactive — they never ask the user anything.** All user interaction happens in the orchestrator (the main loop): Spec runs inline; `plan-agent` and `frontend-developer` only draft to disk and return, and the orchestrator confirms their output. A subagent that calls AskUserQuestion will error.

---

## Settings

Forge behaviour is controlled by `pluginConfigs["forge"].options` in the user's `settings.json`. Read these at the start of every session:

| Setting | Default | Effect |
|---|---|---|
| `tdd_mode` | `false` | If `true`: use `tdd-task-implementer` instead of `task-implementer` for all implementation tasks |
| `auto_research` | `true` | If `true`: run the Research phase automatically. If `false`: ask the user before running Research (it may then be skipped for this task) |
| `strict_wave_review` | `false` | If `true`: run `code-reviewer` after every individual task, not batched per wave |
| `worktree_default` | `""` | If `"worktree"` or `"inline"`: skip the workspace choice question and use this mode |
| `auto_clean` | `false` | If `true`: automatically delete `.forge/` after the Complete phase ships the feature |

**How to read settings:** At the start of a session, check `pluginConfigs["forge"].options` in the user's settings. If unavailable, use the defaults above.

**TDD mode routing:** Wherever these instructions say "invoke `task-implementer`", substitute `tdd-task-implementer` if `tdd_mode` is `true`. The prompt format is identical — just the agent name changes.

**Workspace default:** If `worktree_default` is set to `"worktree"` or `"inline"`, skip the AskUserQuestion at Phase 2 and proceed directly with that mode. Still check git status for worktree mode.

**Strict wave review:** If `strict_wave_review` is `true`, skip the wave-level batch review pattern and instead invoke `code-reviewer` immediately after each individual `task-implementer` result — in both PATH A and PATH B.

**Auto research:** If `auto_research` is `true` (default), run Research automatically at Phase 3. If `false`, ask the user (AskUserQuestion) at the start of Phase 3 whether to run Research first — they may choose to skip it for this task.

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

**Before the Spec phase**, check whether the task involves any UI or UX work.

**UI task signals:** screen, page, view, layout, dashboard, form, modal, drawer, component, button, input, card, table, nav, menu, sidebar, design, style, theme, color, typography, spacing, animation, transition, responsive, flow, onboarding, empty state, loading state.

**If ANY of these apply:** First run **Phase 0.5 (Forge Init)** to establish the feature folder — the `frontend-developer` writes `ui-spec.md` into it, so it must exist before the agent fires. Then use the **Agent tool** to invoke the `frontend-developer` agent before spec:

```
Feature folder: .forge/[feature-name]/

Feature request: [user's original request]

This is a UI/UX task. Read the codebase, commit to an aesthetic direction,
and produce either a full implementation or a precise UI spec written to
ui-spec.md. Do NOT ask the user anything — you run non-interactively. If the
visual direction is ambiguous, pick the strongest option and note it as an
assumption in your return message for the orchestrator to confirm.
```

When the `frontend-developer` returns, **you (the orchestrator) confirm its output with the user** via AskUserQuestion:

```
AskUserQuestion:
  question: "UI direction drafted in ui-spec.md. Does this look right?"
  options: ["Yes, proceed to spec (Recommended)", "I have changes", "Other"]
```

If changes: re-invoke `frontend-developer` with the feedback, then re-confirm. Once confirmed, carry the `ui-spec.md` direction into Phase 1 (Spec) as additional context.

**If the task has NO UI component:** skip Phase 0 and go straight to Phase 1.

---

## Phase 0.5: Forge Init

**Goal:** Create a feature-namespaced session directory under `.forge/` before any phase runs.

Derive a folder name from the user's request: lowercase, hyphenated, max 40 chars (e.g. `add-user-auth`, `fix-rate-limiter`, `redesign-dashboard`).

```bash
FEATURE_NAME="[derived-feature-name]"
mkdir -p ".forge/${FEATURE_NAME}"

cat > ".forge/${FEATURE_NAME}/session.md" << 'EOF'
# Forge Session

## Feature
[feature name from user request]

## Folder
.forge/[feature-name]/

## Started
[timestamp]

## Status
- [ ] UI Check
- [ ] Spec
- [ ] Workspace
- [ ] Research
- [ ] Plan
- [ ] Implement
- [ ] Verify
- [ ] Complete

## Workspace mode
[to be set in Phase 2]

## Branch
[to be set in Phase 2]
EOF
```

All subsequent `.forge/` file references in this session use `.forge/[feature-name]/` as the base path:
- `.forge/[feature-name]/spec.md`
- `.forge/[feature-name]/research.md`
- `.forge/[feature-name]/plan.md`
- `.forge/[feature-name]/ui-spec.md`
- `.forge/[feature-name]/complete.md`

This keeps each feature's session files isolated. Multiple features can have active `.forge/` directories simultaneously without conflict.

This directory persists across context resets — if a session is interrupted, Forge can resume by reading `.forge/[feature-name]/`.

**Two things to carry through the entire session:**

1. **Feature folder.** Every agent you invoke gets `Feature folder: .forge/[feature-name]/` as the first line of its prompt — with `[feature-name]` replaced by the real resolved folder name. Agents read and write all `.forge/` files inside that folder; they do **not** know the feature name unless you tell them. Never dispatch an agent without this line.
2. **Status ticks.** As each phase completes, flip its box in `.forge/[feature-name]/session.md` from `- [ ]` to `- [x]`:
   ```bash
   sed -i 's/- \[ \] [PHASE_NAME]/- [x] [PHASE_NAME]/' ".forge/[feature-name]/session.md"
   ```
   This keeps the session accurately resumable. Tick reminders appear at each gate below.

---

## Phase 1: Spec

**Goal:** Understand exactly what the user wants.

**Run Spec inline — in the main loop, not a subagent.** The Spec phase is an interactive Socratic dialogue, and subagents cannot ask the user questions. Conduct it yourself, using AskUserQuestion for every question.

Follow **`references/spec-dialogue.md`**: ask in rounds (scope → behaviour/edge cases → constraints → validation), stop when you can write an unambiguous design doc, write it to `.forge/[feature-name]/spec.md`, then confirm with the user via AskUserQuestion.

If a UI Check ran in Phase 0, fold the confirmed `ui-spec.md` direction into the spec.

### ⛔ HARD GATE 1 — END OF SPEC

The confirmation question in `spec-dialogue.md` is the gate — do not proceed until the user confirms the spec (or asks for changes, which you make and re-confirm).

**Do not set up the Workspace until the spec is confirmed.**

Once confirmed, tick `Spec` in `.forge/[feature-name]/session.md`.

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
4. Invoke the `dependency-installer` agent to detect the project type and install dependencies:
   - Pass the worktree path
   - Wait for its install report before continuing
   - If install FAILED: include the full error in your report back — do not continue to baseline tests
5. Run the baseline test suite to confirm green

Report back:
- Branch name created
- Worktree path
- Dependency install result (from dependency-installer report)
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

Tick `Workspace` in `.forge/[feature-name]/session.md`.

---

## Phase 3: Research

**Goal:** Build the context needed for accurate planning before a single line of code is written.

**Check `auto_research` first:**
- If `auto_research` is `true` (default): run Research now — do not ask.
- If `auto_research` is `false`: use AskUserQuestion before running the researcher:
  ```
  AskUserQuestion:
    question: "Run the Research phase before planning?"
    options: ["Yes, research first (Recommended)", "Skip research for this task", "Other"]
  ```
  If the user skips: note `Research skipped (auto_research off)` in `session.md` and proceed to Phase 4. Otherwise run the researcher as below.

Do not research inline — only the `researcher` agent runs this phase.

Use the **Agent tool** to invoke the `researcher` agent with this prompt:

```
Feature folder: .forge/[feature-name]/

Read .forge/[feature-name]/spec.md for context, then research the codebase and any
external topics needed to plan this feature accurately.
Write the Research Summary to .forge/[feature-name]/research.md.
```

The researcher reads `.forge/[feature-name]/spec.md` itself — do not paste the spec.

Wait for researcher to return `Research complete — written to .forge/[feature-name]/research.md`, then tick `Research` in `session.md`.

Then proceed directly to Phase 4 — no additional gate after Research.

---

## Phase 4: Plan

**Goal:** Produce a concrete, executable plan — atomic tasks grouped into parallel-safe waves.

Use the **Agent tool** to invoke the `plan-agent` with this prompt:

```
Feature folder: .forge/[feature-name]/

Read .forge/[feature-name]/spec.md and .forge/[feature-name]/research.md, produce a
waved implementation plan, and write it to .forge/[feature-name]/plan.md. Do NOT ask
the user anything — you run non-interactively. Return a short plan summary; the
orchestrator handles approval and execution mode.
Workspace: [worktree at ../worktree-<branch-name> / inline]
```

The plan-agent reads all context from `.forge/[feature-name]/` itself — do not paste spec or research. It writes the plan and returns a summary without asking anything.

**You (the orchestrator) then run approval and execution mode** via AskUserQuestion:

1. Present the plan-agent's summary, then ask:
   ```
   AskUserQuestion:
     question: "Plan written to .forge/[feature-name]/plan.md. Does this look right?"
     options: ["Yes, approve the plan", "I have changes", "Open the plan to review", "Other"]
   ```
   If changes: re-invoke `plan-agent` with the feedback, then re-ask. Do not proceed until approved.

2. Then ask for execution mode:
   ```
   AskUserQuestion:
     question: "How would you like to execute this plan?"
     options: [
       "Sequential — one task at a time. Safer and easier to debug. (Recommended)",
       "Parallel — tasks within each wave run simultaneously. Faster.",
       "Other"
     ]
   ```

Record the chosen mode at the top of `.forge/[feature-name]/plan.md` (`## Execution mode: [Sequential / Parallel]`), update `session.md` with the mode, and tick `Plan`.

### ⛔ HARD GATE 3 — END OF PLAN

**Do not begin any implementation until the user has approved the plan and chosen an execution mode.**

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

For each task in the wave, use the **Agent tool** to invoke `task-implementer` (or `tdd-task-implementer` if tdd_mode is enabled):

```
Feature folder: .forge/[feature-name]/
Task ID: [e.g. Task 1.2]
Workspace: [worktree path or "inline"]
```

The task-implementer reads `.forge/[feature-name]/plan.md` for the task details and conventions, and reads the target file from disk directly. Do not paste task content or file content — pass only the feature folder and task ID.

Wait for each task-implementer to complete before starting the next.

If task-implementer returns **Task Blocked**: log it as 🚫 BLOCKED, continue to next task.

#### Step 2 — Batch review the whole wave

Once ALL tasks in the wave are complete, invoke **one** `code-reviewer` agent per task — but dispatch them all simultaneously using `run_in_background: true`:

For each completed task, use the **Agent tool** with `run_in_background: true`:

```
Feature folder: .forge/[feature-name]/
Task ID: [e.g. Task 1.2]
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

#### Step 4 — Mark wave complete, verify (if enabled), start next wave

Update the progress log with the wave status.

**If `verify_per_wave` is `true`:** Run the full test suite before starting the next wave:
```bash
[project test command]
```
- ✅ All passing → log result, continue to next wave
- ❌ Failures → stop and report to the user. Ask whether to fix now or continue anyway. Do not auto-proceed on failure.

**If `verify_per_wave` is `false` (default):** Start the next wave immediately.

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
Feature folder: .forge/[feature-name]/
Task ID: [e.g. Task 2.1]
Workspace: [worktree path or "inline"]
```

The task-implementer reads `.forge/[feature-name]/plan.md` for task details and conventions, and reads the target file from disk directly. Pass only the feature folder and task ID.

#### Step 3 — Wait for all parallel task-implementers
*(Skip if fully sequential)*

#### Step 4 — Batch-review the parallel wave
*(Skip if fully sequential)*

Once ALL parallel task-implementers in this wave have completed, dispatch one `code-reviewer` per task simultaneously using `run_in_background: true`. This is a wave-level batch — all reviewers fired at once, not one after each individual task.

Prompt for each:
```
Feature folder: .forge/[feature-name]/
Task ID: [e.g. Task 2.1]
Implementer report: [paste only the "What I changed" section from task-implementer output]
```

The code-reviewer reads `.forge/[feature-name]/plan.md` for the original task and conventions, and reads the changed file from disk directly.

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

#### Step 8 — Mark wave complete, verify (if enabled), start next wave

Update the progress log with the wave status.

**If `verify_per_wave` is `true`:** Run the full test suite before starting the next wave:
```bash
[project test command]
```
- ✅ All passing → log result, continue to next wave
- ❌ Failures → stop and report to the user. Ask whether to fix now or continue anyway. Do not auto-proceed on failure.

**If `verify_per_wave` is `false` (default):** Start the next wave immediately.

All tasks must be ✅ or flagged before starting the next wave. Never start the next wave early.

---

### Progress log

The progress log tracks wave status during execution. Raw agent outputs are carried until all waves complete, then dropped at Gate 4B — the one-line-per-task log below is what survives into Verify and Complete.

```
## Execution Progress — [Sequential / Parallel]

### Wave 1 — [label] ✅
- ✅ Task 1.1 — [one line: what was done]
- ✅ Task 1.2 — [one line: what was done]

### Wave 2 — [label] ✅
- ✅ Task 2.1 — [one line: what was done]
- ⚠️ Task 2.2 — STUCK: [brief issue]

### Wave 3 — [label] ⚠️
- 🚫 Task 3.1 — BLOCKED: [reason]
```

At Gate 4B the raw agent outputs are dropped, but this one-line-per-task log is kept verbatim and carried into Verify and Complete.

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

All waves are done. Before asking about tests, finalize the progress log: make sure every task has a one-line status entry (✅/⚠️/🚫). Then **drop all raw task-implementer and code-reviewer output** from the orchestrator context — only the one-line-per-task progress log is retained going forward. (Per-task completion is also on disk via the `[x]` checkboxes in `.forge/[feature-name]/plan.md`, so the session stays resumable.) Then tick `Implement` in `session.md`.

Then use the AskUserQuestion tool:

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

Once green, tick `Verify` in `.forge/[feature-name]/session.md`.

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

Write the completion record and deliver summary:

```bash
cat > ".forge/[feature-name]/complete.md" << 'EOF'
# Complete: [Feature Name]

## What was built
[1–2 sentences]

## Files changed
- `path/to/file` — [what changed]

## Tests
X passed

## Branch
[branch name or "inline"]

## Tasks
[the one-line-per-task progress log]
EOF
```

Tick `Complete` in `.forge/[feature-name]/session.md`.

Then deliver to the user:
```
## ✅ Done

**What was built:** [1–2 sentences]

**Files changed:**
- `path/to/file` — [what changed]

**Tests:** X passed
**Branch:** <branch-name> [if applicable]

Session files saved to .forge/ — resumable if needed.
```

**If `auto_clean` is `true` in settings:** After delivering the summary, automatically run:
```bash
rm -rf ".forge/[feature-name]/"
echo ".forge/[feature-name]/ cleaned up."
```
And append to the summary: `Session files removed (auto_clean enabled).`

**If `auto_clean` is `false` (default):** Leave `.forge/[feature-name]/` in place. The user can run `/forge:clean` to remove it manually.

---

## Reference Files

- `references/spec-dialogue.md` — the inline Spec dialogue procedure (run by the orchestrator)
- `references/planning-guide.md` — wave grouping rules and task sizing
- `references/subagent-instructions.md` — subagent prompt construction and review checklist
- `references/research-summary-template.md` — Research phase output template
