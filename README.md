# Forge

**A structured, agent-driven development workflow for Claude Code.**

Forge is a Claude Code plugin that takes a raw feature request from idea to verified, merged implementation — using a team of specialised agents for each phase, parallel execution where safe, and hard gates that prevent Claude from skipping steps or making assumptions.

---

## How it works

```
[UI Check] → Spec → Workspace → Research → Plan → Implement → Verify → Complete
```

Every phase is handled by a dedicated agent. The orchestrator never writes code — it coordinates. Implementation uses fresh subagents per task with wave-level batch review, running in parallel where file conflicts allow and sequentially where they don't.

---

## Agents

| Agent | Model | Role |
|---|---|---|
| `spec-agent` | Sonnet | Socratic dialogue → confirmed design document |
| `researcher` | Haiku | Codebase scan → research summary |
| `plan-agent` | Sonnet | Research + spec → waved task plan |
| `frontend-developer` | Sonnet | UI/UX tasks → production-grade implementation or spec |
| `task-implementer` | Sonnet | Executes a single task in isolation |
| `code-reviewer` | Sonnet | Two-stage review: spec compliance + code quality |

---

## Features

- **Phase gates** — every phase requires explicit user confirmation before the next begins. Uses `AskUserQuestion` for all user interaction.
- **Spec rounds** — spec-agent asks clarifying questions in topic-grouped rounds (scope, edge cases, constraints) with no hard cap. Stops when the design is genuinely clear.
- **Worktree or inline** — user chooses at the start. Worktree setup runs in the background during Research and Plan so it never blocks.
- **Wave-based parallelism** — the plan is broken into waves. Tasks in the same wave are parallel-safe (no shared files). Tasks in different waves run in dependency order.
- **Batch review** — reviewers fire in parallel across a whole wave after all tasks complete, rather than one at a time.
- **Sequential fallback** — tasks that would conflict within a parallel wave automatically run sequentially.
- **UI department** — `frontend-developer` fires automatically before spec on any UI/UX task. Reads the design system, commits to an aesthetic direction, and produces a full implementation or spec.
- **SessionStart hook** — `using-forge` enforcement context is injected automatically at every session start.
- **Slash commands** — jump directly into any phase: `/forge:spec`, `/forge:plan`, `/forge:implement`, `/forge:review`, `/forge:complete`.
- **Code review skill** — structured handling of PR feedback: categorise, address, respond without scope creep.

---

## Installation

```bash
claude /install forge.skill
```

Then make the session hook executable:

```bash
chmod +x ~/.claude/skills/forge/hooks/session-start.sh
```

Restart Claude Code. Verify:

```bash
/plugin list   # should show: forge
/help          # should show the 5 forge slash commands
```

### Manual install

```bash
unzip forge.skill -d ~/.claude/skills/forge
chmod +x ~/.claude/skills/forge/hooks/session-start.sh
```

---

## Slash commands

| Command | What it does |
|---|---|
| `/forge:spec` | Start the Spec phase — clarify what to build |
| `/forge:plan` | Start the Plan phase — produce a waved task plan |
| `/forge:implement` | Start the Implement phase — execute an approved plan |
| `/forge:review` | Handle incoming PR review feedback |
| `/forge:complete` | Finish — PR, merge, commit, or clean up |

---

## Project structure

```
forge/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── agents/
│   ├── spec-agent.md        # Spec phase — Socratic dialogue
│   ├── researcher.md        # Research phase — codebase scan (Haiku)
│   ├── plan-agent.md        # Plan phase — waved task plan
│   ├── frontend-developer.md # UI/UX — design system + implementation
│   ├── task-implementer.md  # Executes a single implementation task
│   └── code-reviewer.md     # Two-stage review per task
├── commands/
│   ├── spec.md              # /forge:spec
│   ├── plan.md              # /forge:plan
│   ├── implement.md         # /forge:implement
│   ├── review.md            # /forge:review
│   └── complete.md          # /forge:complete
├── hooks/
│   ├── hooks.json           # SessionStart hook config
│   └── session-start.sh     # Injects using-forge at session start
└── skills/
    ├── forge/
    │   ├── SKILL.md         # Main orchestrator skill
    │   └── references/
    │       ├── planning-guide.md
    │       ├── subagent-instructions.md
    │       └── research-summary-template.md
    ├── using-forge/
    │   └── SKILL.md         # Enforcement meta-skill
    └── code-review/
        └── SKILL.md         # PR review response skill
```

---

## Workflow in detail

### 1. UI Check (conditional)
If the task involves anything a user sees or interacts with, `frontend-developer` fires first. It reads the codebase, detects the stack and design system (or builds one if greenfield), commits to an aesthetic direction, and produces either a full implementation or a UI spec — before spec even begins.

### 2. Spec
`spec-agent` runs a multi-round Socratic dialogue. Round 1 covers scope and intent. Round 2 covers edge cases and error handling. Round 3 covers constraints and integrations. It stops when it can write a complete design document without guessing — not when it hits a question count. Produces a structured design doc with problem statement, scope, behaviour, constraints, and testable acceptance criteria.

### 3. Workspace Setup
The user chooses worktree or inline via `AskUserQuestion`. If worktree: git state is checked, then setup (branch creation, dependency install, baseline tests) runs as a background agent immediately — Forge continues to Research without waiting. The worktree is only checked again at Gate 4, right before implementation begins.

### 4. Research
`researcher` (Haiku) scans the codebase — relevant files, existing patterns, naming conventions, error handling, imports, testing setup. Also researches any external topic the feature needs. Produces a structured Research Summary that feeds directly into planning.

### 5. Plan
`plan-agent` reads the confirmed spec and research summary, then produces a waved implementation plan. Each task targets one file, takes 2–5 minutes, and is unambiguous. Tasks are grouped into waves — tasks in the same wave have no file conflicts and can run in parallel. User approves the plan and chooses sequential or parallel execution via `AskUserQuestion`.

### 6. Implement
The orchestrator dispatches `task-implementer` agents per task and `code-reviewer` agents per wave.

**Sequential:** tasks run one at a time; reviewers fire in parallel across the whole wave once all tasks are done.

**Parallel:** tasks within each wave fire simultaneously as background agents; reviewers fire in parallel across the wave once all tasks are done. Tasks that conflict within a wave run sequentially within that wave. Waves always run in order.

Each task gets a fresh agent with minimal context (task + target file + conventions). The reviewer checks spec compliance first, then code quality. Failed reviews trigger a revision loop (max 3 cycles before marking stuck).

### 7. Verify
Full test suite runs from the workspace directory. Must pass before proceeding. Failed tests are fixed and re-run.

### 8. Complete
User chooses how to finish via `AskUserQuestion`: open a GitHub PR, merge locally, commit inline, or keep as-is. Forge executes the chosen option and delivers a summary.

---

## Philosophy

**Durability over speed** — every shortcut that saves a minute now costs an hour debugging later. Forge enforces the steps that matter: confirming scope before planning, planning before coding, testing before merging.

**Agents for isolation, not decoration** — each agent gets a fresh context with only what it needs. This prevents context rot (accumulated history degrading output quality across a long session) and makes each agent's job clear and bounded.

**The orchestrator never codes** — Forge's main skill is a coordinator. It invokes agents, manages gates, and handles user decisions. Code only happens inside `task-implementer`.

**Wave-based parallelism is safe parallelism** — parallel execution only happens within waves where file conflicts have been explicitly checked. The plan itself encodes the safety boundaries.

---

## Requirements

- Claude Code with plugin support
- `gh` CLI (optional — for GitHub PR creation in the Complete phase)
- Git (required for worktree mode)

---

## License

MIT
