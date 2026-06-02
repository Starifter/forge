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
| `/forge:spec` | Jump to Spec — clarify what to build |
| `/forge:plan` | Jump to Plan — produce a waved task plan |
| `/forge:implement` | Jump to Implement — execute an approved plan |
| `/forge:review` | Handle incoming PR review feedback |
| `/forge:complete` | Finish — PR, merge, commit, or clean up |
| `/forge:clean` | Remove `.forge/` session files |

---

## Agents

| Agent | Model | Job |
|---|---|---|
| `spec-agent` | Sonnet | Socratic dialogue in rounds → confirmed design document |
| `researcher` | Haiku | Codebase scan + external research → research summary |
| `plan-agent` | Sonnet | Spec + research → waved task plan |
| `frontend-developer` | Sonnet | UI/UX tasks → production-grade implementation or spec |
| `task-implementer` | Sonnet | Executes one task in isolation |
| `tdd-task-implementer` | Sonnet | Same, with enforced red→green TDD cycle |
| `code-reviewer` | Sonnet | Two-stage review: spec compliance + code quality |
| `context-manager` | Haiku | Compresses completed waves → `.forge/wave-N-summary.md` |
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
| `auto_research` | `true` | Research always runs without asking |
| `strict_wave_review` | `false` | Review after every individual task instead of per wave |
| `worktree_default` | `""` | Pre-select `"worktree"` or `"inline"` to skip the question |
| `auto_clean` | `false` | Delete `.forge/[feature]/` automatically after shipping |
| `verify_per_wave` | `false` | Run full test suite after each wave, not just at the end |

---

## How it works

### UI Check _(conditional)_
If the task involves anything a user sees or interacts with, `frontend-developer` fires before spec. It reads the codebase, detects the stack and existing design system, commits to a bold aesthetic direction, and produces either a full implementation or a precise UI spec. No visual decisions are left to the implementer.

### Spec
`spec-agent` runs a multi-round Socratic dialogue — one topic per round, 3–5 questions max per round. Stops when it can write a complete, unambiguous design document without guessing. Produces a structured doc with problem statement, scope, behaviour, edge cases, constraints, and testable acceptance criteria. Writes to `.forge/[feature]/spec.md`.

### Workspace Setup
User chooses worktree or inline via `AskUserQuestion`. If worktree: `dependency-installer` detects the stack and runs the correct install command, then the baseline test suite runs — all in a background agent. Forge continues to Research and Planning without waiting. The worktree is only checked again right before implementation starts.

### Research
`researcher` (Haiku) scans relevant files, extracts existing patterns and conventions, identifies dependencies, and researches any external topic the feature needs. Writes to `.forge/[feature]/research.md`. Always runs — never skipped.

### Plan
`plan-agent` reads `.forge/[feature]/spec.md` and `.forge/[feature]/research.md`, then produces a waved implementation plan. Every task targets one file, takes 2–5 minutes, and is unambiguous. Tasks are grouped into waves by file-conflict safety. Writes to `.forge/[feature]/plan.md`. User approves the plan and chooses sequential or parallel execution.

### Implement
The orchestrator dispatches agents per task. Each `task-implementer` receives only a task ID — it reads the task from `.forge/[feature]/plan.md` and the target file from disk directly. No content is passed through the orchestrator.

**Sequential:** tasks run one at a time; `code-reviewer` agents fire in parallel across the whole wave once all tasks complete.

**Parallel:** tasks within a wave fire simultaneously as background agents (`run_in_background: true`); reviewers batch across the wave. Tasks that conflict within a wave fall back to sequential automatically. Waves always run in order.

Wave classification is logged before each wave:
```
Wave 2 — Core Logic
Mode: Mixed (3 parallel, 1 sequential)
```

After all waves complete, `context-manager` compresses all wave outputs into `.forge/[feature]/wave-N-summary.md` in one batch pass, and raw outputs are dropped from the orchestrator's context.

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
    ├── wave-1-summary.md   ← compressed wave output
    ├── wave-2-summary.md
    └── complete.md         ← final summary
```

Sessions survive context resets — if Claude Code crashes mid-plan, `.forge/` still has the spec, research, plan, and completed wave summaries. Restart and pick up from the last completed wave.

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

**The orchestrator never codes.** Forge's main skill is a coordinator. Code only happens inside `task-implementer` (or `tdd-task-implementer`). Everything else is orchestration, review, or compression.

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
│   ├── spec-agent.md        # Socratic dialogue → .forge/spec.md
│   ├── researcher.md        # Codebase scan → .forge/research.md (Haiku)
│   ├── plan-agent.md        # Waved plan → .forge/plan.md
│   ├── frontend-developer.md # UI/UX → .forge/ui-spec.md
│   ├── task-implementer.md  # Reads .forge/plan.md, implements task
│   ├── tdd-task-implementer.md # Same with red→green TDD
│   ├── code-reviewer.md     # Reads .forge/plan.md, reviews task
│   ├── context-manager.md   # Writes .forge/wave-N-summary.md (Haiku)
│   └── dependency-installer.md # Detects stack, installs deps (Haiku)
├── commands/
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
    │       ├── planning-guide.md
    │       ├── subagent-instructions.md
    │       └── research-summary-template.md
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
