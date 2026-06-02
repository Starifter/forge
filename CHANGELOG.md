# Changelog

All notable changes to Forge are documented here.

---

## [1.0.0] — Initial Release

### Added

**Core workflow**
- Full phase-gated pipeline: UI Check → Spec → Workspace → Research → Plan → Implement → Verify → Complete
- Hard gates at every phase transition using `AskUserQuestion` — no phase proceeds without explicit user confirmation
- `using-forge` meta-skill injected via SessionStart hook at every session start

**Agents**
- `spec-agent` (Sonnet) — multi-round Socratic dialogue with topic-grouped questions; produces structured design document with acceptance criteria
- `researcher` (Haiku) — codebase scan + external topic research; produces structured Research Summary
- `plan-agent` (Sonnet) — converts spec + research into waved task plan; collects plan approval and execution mode in one step
- `frontend-developer` (Sonnet) — fires before spec on UI/UX tasks; reads design system, commits to aesthetic direction, produces full implementation or UI spec
- `task-implementer` (Sonnet) — executes a single task in isolated context
- `code-reviewer` (Sonnet) — two-stage review: spec compliance then code quality; returns APPROVED or NEEDS REVISION with specifics

**Execution**
- Wave-based parallelism: tasks grouped by file-conflict safety; parallel-safe tasks run simultaneously, conflicted tasks run sequentially within the wave
- Wave-level batch review: all reviewers for a wave fire simultaneously after all tasks complete — not one after each task
- Sequential mode: tasks run one at a time; batch review still fires in parallel across each wave
- Parallel mode: tasks dispatch with `run_in_background: true`; reviewers batch per wave
- Revision loops: up to 3 cycles per task before marking stuck; NEEDS REVISION triggers targeted re-implementation

**Workspace**
- User chooses worktree or inline at the start
- Worktree setup runs as a background agent during Research + Plan — never blocks
- Worktree check at Gate 4 before implementation begins; baseline failure stops implementation with options to fix or switch to inline

**Slash commands**
- `/forge:spec` — jump to Spec phase
- `/forge:plan` — jump to Plan phase
- `/forge:implement` — jump to Implement phase
- `/forge:review` — invoke code review skill for PR feedback
- `/forge:complete` — jump to Complete phase

**Skills**
- `forge` — main orchestrator skill
- `using-forge` — enforcement meta-skill with 1% rule and gate table
- `code-review` — structured PR review response: categorise feedback, address changes, write PR reply without scope creep
