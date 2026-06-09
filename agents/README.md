# Agents

Each agent is a specialised worker with a focused job and a bounded context. The orchestrator (`skills/forge/SKILL.md`) invokes them via the Agent tool — agents never invoke each other directly except where the orchestrator explicitly chains them.

**All agents run non-interactively** — they have no channel to the user and must never call `AskUserQuestion`. Every user-facing question is asked by the orchestrator. (The **Spec** phase is interactive, so it has no agent — the orchestrator runs it inline, following `skills/forge/references/spec-dialogue.md`.)

---

## Roster

### `researcher` — Haiku
Runs the Research phase. Reads relevant files, extracts existing patterns and conventions, identifies dependencies and integrations, and researches any external topic the feature needs. Returns a structured Research Summary. Runs on Haiku because the work is mechanical (reading + extracting), not reasoning.

### `plan-agent` — Sonnet
Drafts the Plan. Reads the confirmed spec and research summary, then produces a waved implementation plan. Every task targets one file, takes 2–5 minutes, and is unambiguous. Tasks are grouped into waves by file-conflict safety. Writes the plan to disk and returns a summary non-interactively — the orchestrator presents it and collects approval + execution mode (sequential/parallel) from the user.

### `frontend-developer` — Sonnet
Handles UI/UX tasks. Fires before spec when the request involves anything a user sees or interacts with. Reads the project's design system (or identifies that one needs to be built), commits to a bold aesthetic direction, and produces either a full implementation or a precise UI spec depending on scope. All states must be designed (default, hover, focus, loading, error, empty, disabled). Runs non-interactively — resolves visual ambiguity itself and returns; the orchestrator confirms the direction. Never produces generic output.

### `task-implementer` — Sonnet
Executes a single implementation task in isolation. Receives only: the task description, the target file, and coding conventions. Does not receive full conversation history or the entire plan. Returns a report of what changed, any deviations, and any assumptions. Returns a blocker report instead of guessing when context is missing.

### `code-reviewer` — Sonnet
Reviews a completed task in two stages. Stage 1: spec compliance — did the output match the task exactly, was only the correct file touched? Stage 2: code quality — any bugs, convention violations, dead code? Returns APPROVED or NEEDS REVISION with specific details. Cannot write or edit files.

---

## Design principles

**Bounded context.** Each agent gets the minimum context needed for its job. This prevents context rot (accumulated history degrading output quality) and keeps each agent fast and focused.

**No agent-to-agent invocation.** Agents don't spawn other agents. The orchestrator coordinates everything. This keeps the execution graph explicit and debuggable.

**Interaction lives in the orchestrator.** Subagents run non-interactively and cannot reach the user — calling `AskUserQuestion` inside one errors. So every question (spec dialogue, plan approval, execution mode, UI confirmation, finish options) is asked by the orchestrator. Agents that need a decision draft their best attempt, surface assumptions in their return message, and let the orchestrator confirm.

**Model choice reflects the work.** Haiku for mechanical extraction (researcher). Sonnet for reasoning and generation (everything else). Don't add Opus-level work to the inner loop — it will slow every task.

**Failure modes are explicit.** `task-implementer` returns a structured blocker report rather than partially implementing and guessing. `code-reviewer` returns NEEDS REVISION with specifics rather than vague feedback. This makes revision loops fast and targeted.
