# Skills

Skills are the orchestration layer. They define when Forge fires, how phases are sequenced, and what the enforcement rules are. Unlike agents (which do work), skills coordinate work.

---

## `forge/` — Main orchestrator

`forge/SKILL.md` is the heart of the plugin. It defines the full workflow:

```
[UI Check] → Spec → Workspace → Research → Plan → Implement → Verify → Complete
```

Each phase invokes one or more agents via the Agent tool. Hard gates (⛔) mark where Claude must stop and get explicit user confirmation before continuing. All user interaction uses `AskUserQuestion`.

**References** are supporting files loaded on demand:
- `planning-guide.md` — wave grouping rules, task sizing, common mistakes
- `subagent-instructions.md` — how to construct task-implementer prompts and run wave-level batch review
- `research-summary-template.md` — the structured template researcher fills out

### When it triggers
Any task description containing implementation intent: "build", "add", "implement", "create", "fix", "refactor", or similar. The `using-forge` skill's 1% rule also ensures it fires when there's any doubt.

---

## `using-forge/` — Enforcement meta-skill

`using-forge/SKILL.md` is injected at every session start via the SessionStart hook. Its job is to make sure Forge is never skipped and no gate is ever rationalised away.

Contains:
- The **1% rule** — if there's any chance code is being touched, invoke Forge
- The **gate table** — what must happen at each gate before proceeding
- A **rationalisations table** — common excuses Claude might use to skip steps, each one blocked

### Why a separate skill?
The main `forge` skill is loaded when a task triggers it. `using-forge` is always present from session start — it acts as a persistent background constraint rather than a reactive workflow.

---

## `code-review/` — PR review response

`code-review/SKILL.md` handles incoming code review feedback from human reviewers. Triggered by `/forge:review` or when the user pastes review comments.

Workflow:
1. Read all feedback before touching any code
2. Categorise each comment: Required / Requested / Discussion / Nitpick
3. Confirm Discussion items with the user before implementing
4. Fix Required and Requested items
5. Run tests
6. Write a structured PR reply summary

Prevents scope creep, defensive changes, and silent disagreement — the three most common ways review responses go wrong.
