---
description: Semi-autonomous forge. You answer Spec + Plan questions and approve the plan; then it implements and verifies UNATTENDED in an isolated worktree and reports back. Stops after Verify with a green branch committed locally — never pushes/PRs. Auto-retries failures up to 3×, then halts with a report.
disable-model-invocation: true
argument-hint: "<task description>"
---

Invoke the `autonomous-forge` skill for this task:

**Task:** $ARGUMENTS

How this run works:
- **Spec and Plan are interactive** — ask the user questions to shape the spec (Socratic dialogue), then draft a plan and get the user's approval + execution mode. Stay in the loop here; use AskUserQuestion.
- **Once the plan is approved, hand off to unattended execution** — implement and verify with NO further questions. If a decision arises mid-execution, make the safest reasonable choice, record it as an assumption, and continue (or halt and report).
- Work only in an isolated git worktree on a new branch — never the current tree.
- On a failing task or red tests: auto-retry up to `auto_max_fix_attempts` (default 3), then HALT and write a report.
- Stop after Verify with the work committed locally in the worktree. Do not push, open a PR, or merge.

If `$ARGUMENTS` is empty, ask the user to re-run as `/forge:auto "<what to build>"`.
