<div align="center">

# 🔨 Forge

**A structured, agent-driven development workflow for Claude Code.**

[![Version](https://img.shields.io/badge/version-1.4.5-orange?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-blueviolet?style=flat-square)](https://code.claude.com)

Forge takes a raw feature request from idea to verified, merged implementation — using a team of specialised agents for each phase, hard gates that prevent skipping steps, and parallel execution where safe.

</div>

---

## Pipeline

```
[UI Check] → Spec → Workspace → Research → Plan → Implement → Verify → Complete
```

Every phase is handled by a dedicated agent. The orchestrator never writes code — it coordinates. Each agent gets a fresh context with only what it needs, reads from `.forge/[feature-name]/` on disk, and writes its output back there. No content is passed through the orchestrator's context.

---

## Install

```bash
claude /install forge.skill
```

Or install directly from GitHub:

```bash
/plugin install https://github.com/starifter/forge
```

After installing, make the session hook executable:

```bash
chmod +x ~/.claude/skills/forge/hooks/session-start.sh
```

Restart Claude Code to activate the SessionStart hook.

> **Requirements:** Claude Code · Git (for worktree mode) · `gh` CLI (optional, for PR creation)

---

## Slash commands

| Command | Phase |
|---|---|
| `/forge:auto "<task>"` | **Unattended run** — full pipeline, no questions, stops after Verify |
| `/forge:spec` | Jump to Spec — clarify what to build |
| `/forge:plan` | Jump to Plan — produce a waved task plan |
| `/forge:implement` | Jump to Implement — execute an approved plan |
| `/forge:review` | Handle incoming PR review feedback |
| `/forge:complete` | Finish — PR, merge, commit, or clean up |
| `/forge:clean` | Remove `.forge/` session files |

---

## Autonomous mode (`/forge:auto`)

`/forge:auto "<task>"` runs the **entire pipeline unattended** — no questions, suitable for leaving in the background. It makes every decision itself and records the ones it had to assume.

```
/forge:auto "add a /health endpoint that returns build SHA and uptime as JSON"
```

What it does, end to end:
1. **Auto-Spec** — derives the spec from your task text (no dialogue); records every assumption in `spec.md`.
2. **Worktree** — always isolates work in a new git worktree + branch (never your current tree). Installs deps, checks the baseline is green.
3. **Research → Plan** — runs the researcher, drafts a waved plan, and auto-approves it.
4. **Implement** — executes the waves with the same 2-stage review as interactive forge. On a failing task it auto-retries up to `auto_max_fix_attempts` (default 3).
5. **Verify** — runs the suite; fixes and re-runs up to the same budget.
6. **Stops** — commits the green work **locally in the worktree** and writes a report. It does **not** push, open a PR, or merge — shipping is your call.

If anything can't be resolved (dirty tree, red baseline, a task that won't pass, tests still failing after retries), it **halts and writes `.forge/[feature]/auto-report.md`** saying exactly where and why — never a faked success. State lives in `.forge/[feature]/`, so you can take over interactively with `/forge` from where it stopped.

The richer your task description, the fewer assumptions it has to make. Tune behaviour with `auto_execution_mode` and `auto_max_fix_attempts` (see Settings).

---

## Agents

All agents run **non-interactively** — they draft to disk and return. Every user-facing question is asked by the orchestrator. The **Spec** phase is therefore not an agent: it's an interactive dialogue run inline in the orchestrator.

| Agent | Model | Job |
|---|---|---|
| `researcher` | Haiku | Codebase scan + external research → research summary |
| `plan-agent` | Sonnet | Spec + research → waved task plan (drafts; orchestrator approves) |
| `frontend-developer` | Sonnet | UI/UX tasks → implementation or spec (drafts; orchestrator confirms) |
| `task-implementer` | Sonnet | Executes one task in isolation |
| `tdd-task-implementer` | Sonnet | Same, with enforced red→green TDD cycle |
| `code-reviewer` | Sonnet | Two-stage review: spec compliance + code quality |
| `dependency-installer` | Haiku | Detects stack, runs correct install command |

---

## Settings

Configure Forge behaviour when installing — or change anytime:

```bash
/plugin config forge tdd_mode true
```

| Setting | Default | Effect |
|---|---|---|
| `tdd_mode` | `false` | Use `tdd-task-implementer` — enforced red→green TDD per task |
| `auto_research` | `true` | Research runs automatically; set `false` to confirm (and optionally skip) it first |
| `strict_wave_review` | `false` | Review after every individual task instead of per wave |
| `worktree_default` | `""` | Pre-select `"worktree"` or `"inline"` to skip the question |
| `auto_clean` | `false` | Delete `.forge/[feature]/` automatically after shipping |
| `verify_per_wave` | `false` | Run full test suite after each wave, not just at the end |
| `auto_execution_mode` | `"sequential"` | `/forge:auto` wave execution: `"sequential"` or `"parallel"` |
| `auto_max_fix_attempts` | `3` | `/forge:auto` retries before halting on a failing task or red tests |

---

## How it works

### UI Check _(conditional)_
If the task involves anything a user sees or interacts with, `frontend-developer` fires before spec. It reads the codebase, detects the stack and existing design system, commits to a bold aesthetic direction, and produces either a full implementation or a precise UI spec — non-interactively. The orchestrator then confirms the direction with you. No visual decisions are left to the implementer.

### Spec
Spec runs **inline in the orchestrator** (the main loop), because it's an interactive Socratic dialogue and subagents can't ask you questions. One topic per round, 3–5 questions max per round, via `AskUserQuestion`. Stops when it can write a complete, unambiguous design document without guessing. Produces a structured doc with problem statement, scope, behaviour, edge cases, constraints, and testable acceptance criteria. Writes to `.forge/[feature]/spec.md`.

### Workspace Setup
User chooses worktree or inline via `AskUserQuestion`. If worktree: `dependency-installer` detects the stack and runs the correct install command, then the baseline test suite runs — all in a background agent. Forge continues to Research and Planning without waiting. The worktree is only checked again right before implementation starts.

### Research
`researcher` (Haiku) scans relevant files, extracts existing patterns and conventions, identifies dependencies, and researches any external topic the feature needs. Writes to `.forge/[feature]/research.md`. Runs by default — skippable only when `auto_research` is off and the user opts out.

### Plan
`plan-agent` reads `.forge/[feature]/spec.md` and `.forge/[feature]/research.md`, then produces a waved implementation plan. Every task targets one file, takes 2–5 minutes, and is unambiguous. Tasks are grouped into waves by file-conflict safety. It writes the plan to `.forge/[feature]/plan.md` and returns a summary non-interactively; the orchestrator presents it and you approve the plan and choose sequential or parallel execution.

### Implement
The orchestrator dispatches agents per task. Each `task-implementer` receives only a task ID — it reads the task from `.forge/[feature]/plan.md` and the target file from disk directly. No content is passed through the orchestrator.

**Sequential:** tasks run one at a time; `code-reviewer` agents fire in parallel across the whole wave once all tasks complete.

**Parallel:** tasks within a wave fire simultaneously as background agents (`run_in_background: true`); reviewers batch across the wave. Tasks that conflict within a wave fall back to sequential automatically. Waves always run in order.

Wave classification is logged before each wave:
```
Wave 2 — Core Logic
Mode: Mixed (3 parallel, 1 sequential)
```

After all waves complete, the raw task-implementer and code-reviewer outputs are dropped from the orchestrator's context. The one-line-per-task progress log is kept in context, and per-task completion stays on disk as `[x]` checkboxes in `plan.md`.

### Verify
Full test suite runs once, after all waves complete. Failed tests are fixed and re-run before proceeding. With `verify_per_wave: true`, the suite also runs after each individual wave.

### Complete
User chooses how to finish: open a GitHub PR, merge locally, commit inline, or keep as-is. With `auto_clean: true`, `.forge/[feature]/` is deleted automatically after shipping.

---

## Session files

Each feature gets its own directory under `.forge/`:

```
.forge/
└── add-user-auth/
    ├── session.md          ← phase status, workspace mode, branch
    ├── spec.md             ← confirmed design document
    ├── research.md         ← codebase scan + findings
    ├── ui-spec.md          ← UI output (if applicable)
    ├── plan.md             ← waved task plan with checkboxes
    └── complete.md         ← final summary
```

Sessions survive context resets — if Claude Code crashes mid-plan, `.forge/` still has the spec, research, and the plan with completed tasks checked off. Restart and pick up from the last unchecked task.

Add `.forge/` to your project's `.gitignore` unless you want to commit session state.

---

## Dependency detection

`dependency-installer` reads the project manifest and runs the correct command — no guessing:

| Stack | Detection | Command |
|---|---|---|
| Bun | `bun.lockb` | `bun install` |
| pnpm | `pnpm-lock.yaml` | `pnpm install` |
| Yarn | `yarn.lock` | `yarn install` |
| npm | `package-lock.json` | `npm ci` |
| uv | `uv.lock` | `uv sync` |
| Poetry | `poetry.lock` | `poetry install` |
| Pipenv | `Pipfile.lock` | `pipenv install` |
| pip | `requirements.txt` | `pip install -r requirements.txt` |
| Ruby | `Gemfile` | `bundle install` |
| Go | `go.mod` | `go mod download` |
| Rust | `Cargo.toml` | `cargo fetch` |
| PHP | `composer.json` | `composer install` |

Polyglot projects install all detected stacks in dependency order. Already-installed deps are skipped.

---

## Philosophy

**The orchestrator never codes.** Forge's main skill is a coordinator. Code only happens inside `task-implementer` (or `tdd-task-implementer`). Everything else is orchestration or review.

**Agents for isolation, not decoration.** Each agent gets a fresh context with only what it needs for its specific job. This prevents context rot — where accumulated history degrades output quality across a long session. A 20-task plan runs just as well as a 3-task plan.

**Files over context.** Agents write their outputs to `.forge/[feature]/` and read from disk. The orchestrator holds file paths, not content. Context stays flat regardless of plan size.

**Wave-based parallelism is safe parallelism.** Parallel execution only happens within waves where file conflicts have been explicitly checked. The plan itself encodes the safety boundaries — no speculative parallelism.

**Hard gates are non-negotiable.** Every phase requires explicit user confirmation via `AskUserQuestion`. No phase proceeds on assumption. The `using-forge` meta-skill is injected at every session start to enforce this even when the orchestrator tries to rationalise skipping a step.

---

## Project structure

```
forge/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest + userConfig settings
│   └── marketplace.json     # Marketplace catalog entry
├── agents/
│   ├── researcher.md        # Codebase scan → .forge/[feature]/research.md (Haiku)
│   ├── plan-agent.md        # Waved plan → .forge/[feature]/plan.md
│   ├── frontend-developer.md # UI/UX → .forge/[feature]/ui-spec.md
│   ├── task-implementer.md  # Reads .forge/[feature]/plan.md, implements task
│   ├── tdd-task-implementer.md # Same with red→green TDD
│   ├── code-reviewer.md     # Reads .forge/[feature]/plan.md, reviews task
│   └── dependency-installer.md # Detects stack, installs deps (Haiku)
├── commands/
│   ├── auto.md              # /forge:auto — unattended run
│   ├── spec.md              # /forge:spec
│   ├── plan.md              # /forge:plan
│   ├── implement.md         # /forge:implement
│   ├── review.md            # /forge:review
│   ├── complete.md          # /forge:complete
│   └── clean.md             # /forge:clean
├── hooks/
│   ├── hooks.json           # SessionStart hook registration
│   └── session-start.sh     # Injects using-forge + settings at session start
├── settings.json            # Default settings applied on install
└── skills/
    ├── forge/
    │   ├── SKILL.md         # Main orchestrator — full pipeline
    │   └── references/
    │       ├── spec-dialogue.md          # Inline Spec procedure (run by orchestrator)
    │       ├── planning-guide.md
    │       ├── subagent-instructions.md
    │       └── research-summary-template.md
    ├── autonomous-forge/
    │   └── SKILL.md         # Unattended pipeline (/forge:auto)
    ├── using-forge/
    │   └── SKILL.md         # Enforcement meta-skill (SessionStart)
    └── code-review/
        └── SKILL.md         # PR review response skill
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add phases, modify agents, change enforcement rules, and test changes locally.

---

## License

MIT — see [LICENSE](LICENSE).
