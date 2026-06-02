# Changelog

---

## [1.4.5] — verify_per_wave setting

### Added
- `verify_per_wave` setting (default `false`) — runs the full test suite after each wave completes before starting the next. Catches regressions earlier at the cost of slower implementation. Final Verify phase always runs regardless.

---

## [1.4.4] — Feature-namespaced session folders

### Changed
- `.forge/` now creates a subfolder per feature: `.forge/[feature-name]/`
- Multiple features can have active session directories simultaneously without conflict
- `auto_clean` now deletes only the specific feature folder, not the entire `.forge/` directory
- All agents updated to use the feature-namespaced path
- `/forge:clean` now lists all feature folders and asks which to remove, with an "All" option

---

## [1.4.3] — auto_clean setting

### Added
- `auto_clean` setting (default `false`) — automatically deletes `.forge/[feature]/` at the end of the Complete phase when a feature ships

---

## [1.4.2] — /forge:clean command

### Added
- `/forge:clean` command — removes `.forge/` session files. Lists feature folders and asks which to clean via `AskUserQuestion`.

---

## [1.4.1] — End-of-implementation compression

### Changed
- Context compression now runs once after all waves complete (at Gate 4B), not after every individual wave
- `context-manager` handles batch compression of all waves in a single invocation
- Orchestrator carries raw wave outputs through implementation without interruption — better quality during active work

---

## [1.4.0] — File-based context (.forge/)

### Added
- `.forge/[feature]/` session directory — every agent writes its output to disk instead of returning content through the orchestrator
- `session.md` — phase status, workspace mode, branch name
- `spec.md` — confirmed design document
- `research.md` — codebase scan and findings
- `ui-spec.md` — UI implementation or spec
- `plan.md` — waved task plan with live checkboxes
- `wave-N-summary.md` — compressed wave output
- `complete.md` — final summary
- Phase 0.5: Forge Init — creates the session directory before any phase runs
- Sessions survive context resets — resumable from last completed wave

### Changed
- All agents read from `.forge/` directly instead of receiving pasted content in prompts
- Orchestrator holds file paths, not content — context stays flat regardless of plan size
- `task-implementer` and `code-reviewer` receive task IDs only, read task details from `plan.md`

---

## [1.3.0] — Dependency installer

### Added
- `dependency-installer` agent (Haiku) — detects project stack from manifest files and runs the correct install command with zero guessing
- Supports: Bun, pnpm, Yarn, npm, uv, Poetry, Pipenv, pip, Ruby/Bundler, Go, Rust/Cargo, PHP/Composer
- Handles polyglot projects (installs all detected stacks in dependency order)
- Skips install if dependencies are already current
- Reports failures with diagnosis and suggested fix

### Changed
- Worktree setup now invokes `dependency-installer` instead of guessing the install command

---

## [1.2.0] — Context management

### Added
- `context-manager` agent (Haiku) — two jobs: batch wave compression and subagent prompt validation
- Wave compression: after all waves complete, compresses all wave outputs into compact `wave-N-summary.md` files and drops raw outputs
- Prompt validation: checks subagent prompt size before dispatch, trims in safe order if over budget (file content → signatures → truncation)

### Changed
- Critical rules updated: rule 7 (compress after all waves), rule 8 (validate prompts before dispatch)
- Progress log tracks wave status during execution; raw output dropped at Gate 4B

---

## [1.1.0] — TDD mode + user settings

### Added
- `userConfig` in `plugin.json` — Claude Code prompts users for settings on install
- `settings.json` at plugin root with defaults
- `tdd_mode` setting (default `false`) — routes all tasks through `tdd-task-implementer`
- `auto_research` setting (default `true`) — research always runs without asking
- `strict_wave_review` setting (default `false`) — reviews after every task instead of per wave
- `worktree_default` setting — pre-select workspace mode
- `tdd-task-implementer` agent — enforces strict red→green TDD per task: write failing test, implement minimum to pass, confirm suite green
- Session-start hook now injects current settings alongside enforcement context

---

## [1.0.0] — Initial release

### Added

**Core workflow**
- Full phase-gated pipeline: UI Check → Spec → Workspace → Research → Plan → Implement → Verify → Complete
- Hard gates at every phase transition using `AskUserQuestion`
- `using-forge` meta-skill with 1% rule and gate enforcement table
- SessionStart hook injects enforcement context at every session start

**Agents**
- `spec-agent` (Sonnet) — multi-round Socratic dialogue, structured design document
- `researcher` (Haiku) — codebase scan + research summary
- `plan-agent` (Sonnet) — waved task plan with plan approval and execution mode
- `frontend-developer` (Sonnet) — fires before spec on UI/UX tasks, bold aesthetic direction
- `task-implementer` (Sonnet) — isolated single-task execution
- `code-reviewer` (Sonnet) — two-stage review per task

**Execution**
- Wave-based parallelism: tasks grouped by file-conflict safety
- Three wave modes: Fully parallel / Mixed / Fully sequential (auto-classified)
- Wave-level batch review: all reviewers for a wave fire simultaneously
- Parallel tasks dispatch with `run_in_background: true`
- Revision loops: up to 3 cycles before marking stuck

**Workspace**
- User chooses worktree or inline via `AskUserQuestion`
- Worktree setup runs as background agent during Research + Plan
- Worktree check at Gate 4 before implementation

**Slash commands**
- `/forge:spec`, `/forge:plan`, `/forge:implement`, `/forge:review`, `/forge:complete`

**Skills**
- `forge` — main orchestrator
- `using-forge` — enforcement meta-skill
- `code-review` — structured PR review response
