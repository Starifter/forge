# Agents

Each agent is a specialised worker with a focused job and a bounded context. The orchestrator (`skills/forge/SKILL.md`) invokes them via the Agent tool — agents never invoke each other directly except where the orchestrator explicitly chains them.

---

## Roster

### `spec-agent` — Sonnet
Runs the Spec phase. Conducts a Socratic dialogue in topic-grouped rounds to understand what the user wants to build. Produces a structured design document with problem statement, scope, behaviour, constraints, and testable acceptance criteria. Uses `AskUserQuestion` for every question. Does not return until the user confirms the design doc.

### `researcher` — Haiku
Runs the Research phase. Reads relevant files, extracts existing patterns and conventions, identifies dependencies and integrations, and researches any external topic the feature needs. Returns a structured Research Summary. Runs on Haiku because the work is mechanical (reading + extracting), not reasoning.

### `plan-agent` — Sonnet
Runs the Plan phase. Reads the confirmed spec and research summary, then produces a waved implementation plan. Every task targets one file, takes 2–5 minutes, and is unambiguous. Tasks are grouped into waves by file-conflict safety. Collects plan approval and execution mode (sequential/parallel) from the user via `AskUserQuestion` before returning.

### `frontend-developer` — Sonnet
Handles UI/UX tasks. Fires before spec when the request involves anything a user sees or interacts with. Reads the project's design system (or identifies that one needs to be built), commits to a bold aesthetic direction, and produces either a full implementation or a precise UI spec depending on scope. All states must be designed (default, hover, focus, loading, error, empty, disabled). Never produces generic output.

### `task-implementer` — Sonnet
Executes a single implementation task in isolation. Receives only: the task description, the target file, and coding conventions. Does not receive full conversation history or the entire plan. Returns a report of what changed, any deviations, and any assumptions. Returns a blocker report instead of guessing when context is missing.

### `code-reviewer` — Sonnet
Reviews a completed task in two stages. Stage 1: spec compliance — did the output match the task exactly, was only the correct file touched? Stage 2: code quality — any bugs, convention violations, dead code? Returns APPROVED or NEEDS REVISION with specific details. Cannot write or edit files.

---

## Design principles

**Bounded context.** Each agent gets the minimum context needed for its job. This prevents context rot (accumulated history degrading output quality) and keeps each agent fast and focused.

**No agent-to-agent invocation.** Agents don't spawn other agents. The orchestrator coordinates everything. This keeps the execution graph explicit and debuggable.

**Model choice reflects the work.** Haiku for mechanical extraction (researcher). Sonnet for reasoning and generation (everything else). Don't add Opus-level work to the inner loop — it will slow every task.

**Failure modes are explicit.** `task-implementer` returns a structured blocker report rather than partially implementing and guessing. `code-reviewer` returns NEEDS REVISION with specifics rather than vague feedback. This makes revision loops fast and targeted.
