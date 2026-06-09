---
description: Run forge unattended in the background. Give it a task and it runs Spec → Research → Plan → Implement → Verify with NO questions, in an isolated worktree, then stops with a green branch committed locally for you to review. Auto-retries failures up to 3×, then halts with a report.
disable-model-invocation: true
argument-hint: "<task description — the richer the better>"
---

Invoke the `autonomous-forge` skill and run the full unattended pipeline for this task:

**Task:** $ARGUMENTS

Rules for this run:
- **Never** ask the user anything (no AskUserQuestion). Make the safest reasonable decision, record it as an assumption, and continue.
- Work only in an isolated git worktree on a new branch — never the current tree.
- Run Spec (auto-derived from the task), Research, Plan (auto-approved), Implement (with 2-stage review), and Verify.
- On a failing task or red tests: auto-retry up to `auto_max_fix_attempts` (default 3), then HALT and write a report.
- Stop after Verify with the work committed locally in the worktree. Do not push, open a PR, or merge.
- If the task description is empty or too vague to act on, halt immediately and say a task description is required.

If `$ARGUMENTS` is empty, ask the user to re-run as `/forge:auto "<what to build>"`.
