# Commands

Slash commands let you jump directly into a specific Forge phase without waiting for the workflow to trigger automatically. All commands use `disable-model-invocation: true` — they're user-only and cannot be self-invoked by the agent.

---

## `/forge:spec`
Starts the Spec phase directly. `spec-agent` asks clarifying questions in rounds, writes a design document, and confirms with the user before finishing. Use this when you want to nail down requirements before anything else.

## `/forge:plan`
Starts the Plan phase directly. Assumes Spec is already confirmed. `plan-agent` reads the research summary (run research first if needed) and produces a waved task plan. Collects plan approval and execution mode before returning.

## `/forge:implement`
Starts the Implement phase directly. Assumes an approved plan exists. Asks for sequential or parallel execution via `AskUserQuestion`, then dispatches `task-implementer` and `code-reviewer` agents per wave.

## `/forge:review`
Invokes the `code-review` skill to handle incoming PR feedback. Categorises all comments, addresses them without scope creep, and writes a PR reply summary.

## `/forge:complete`
Jumps to the Complete phase. Assumes Verify has passed. Offers finish options via `AskUserQuestion`: GitHub PR, local merge, inline commit, or keep as-is. Executes the chosen option and delivers a summary.

---

## Notes

Commands are thin wrappers — they redirect to the relevant skill or agent phase. The full Forge workflow (triggered automatically by describing a task) handles sequencing between phases. Commands let you re-enter at a specific point or skip ahead when you know what you need.
