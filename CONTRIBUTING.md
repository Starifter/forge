# Contributing to Forge

---

## Architecture overview

```
skills/forge/SKILL.md          ← orchestrator — coordinates phases, never writes code
skills/using-forge/SKILL.md    ← enforcement meta-skill — injected at session start
skills/code-review/SKILL.md    ← PR review response skill
agents/*.md                    ← workers — each does one job and writes to .forge/
commands/*.md                  ← slash command wrappers
hooks/session-start.sh         ← injects using-forge + settings at session start
.claude-plugin/plugin.json     ← manifest + userConfig settings schema
settings.json                  ← default setting values applied on install
```

The key architectural rule: **agents write to `.forge/[feature-name]/`, they don't return content to the orchestrator.** The orchestrator passes task IDs and file paths, never content.

---

## Making changes

### Changing a phase's behaviour
Edit the relevant agent in `agents/`. The `description` frontmatter field controls when Claude auto-invokes it — keep it specific. The body contains the agent's full instructions.

### Changing orchestration logic
Edit `skills/forge/SKILL.md`. Pay close attention to:
- **HARD GATE sections** — these are what prevent Claude from skipping phases. Changing them affects enforcement.
- **`.forge/` file references** — if you add a new output file, update both the producing agent and consuming agents consistently.
- **Settings section** — if you add a new setting, document it in the table.

### Changing enforcement rules
Edit `skills/using-forge/SKILL.md`. This is injected at every session start. Changes here affect every session immediately after reinstall.

### Adding a new agent
1. Create `agents/your-agent.md` with YAML frontmatter (`name`, `description`, `model`, `effort`, `maxTurns`)
2. Add a write step: the agent should write its output to `.forge/[feature-name]/your-output.md`
3. Reference it by name in `skills/forge/SKILL.md` using the Agent tool pattern
4. Update `agents/README.md` with the new agent's role

### Adding a new setting
1. Add to `userConfig` in `.claude-plugin/plugin.json` with `type`, `title`, `description`
2. Add the default to `settings.json` under `pluginConfigs.forge.options`
3. Add to the settings table in `skills/forge/SKILL.md`
4. Add conditional logic in the relevant phase/agent
5. Update `session-start.sh` if the setting needs to be injected as context

### Adding a slash command
1. Create `commands/your-command.md` with `disable-model-invocation: true` in frontmatter
2. Write a brief instruction body that redirects to the relevant skill/phase
3. Update `commands/README.md`

---

## Principles to maintain

**The orchestrator never codes.** `skills/forge/SKILL.md` invokes agents — it never writes implementation itself.

**Agents write to `.forge/`, they don't return content.** Pass task IDs and file paths. Never paste file content or prior agent outputs into prompts.

**Hard gates are non-negotiable.** Every user-facing decision goes through `AskUserQuestion`. Every phase has an explicit gate. Do not add phases that can be silently skipped.

**Haiku for mechanical work.** `researcher`, `context-manager`, and `dependency-installer` run on Haiku because their work is mechanical (reading, extracting, compressing). Agents that reason or generate code run on Sonnet.

**Wave-level batch review, not per-task.** Don't revert the batching — it's a meaningful speed improvement. The only exception is `strict_wave_review: true` in settings.

**Fresh context per agent invocation.** Each agent should be able to complete its job from a cold start using only what's in `.forge/` and the codebase on disk.

---

## Testing

Install the plugin locally and test against a real small project:

```bash
# Install from local directory
claude plugin install --plugin-dir ./forge

# Or reinstall from the packaged .skill file
claude /install forge.skill
```

Test the full workflow with a simple feature. Check:
- `AskUserQuestion` fires at every gate (no plain-text questions)
- `.forge/[feature-name]/` is created with the right structure
- Worktree setup runs in background without blocking Research
- Wave classification logs correctly (Fully parallel / Mixed / Fully sequential)
- Batch review fires per wave, not per task
- `context-manager` runs once after all waves, not per wave
- `using-forge` context appears at session start
- Settings take effect when configured

---

## Submitting changes

1. Fork the repo
2. Branch: `git checkout -b fix/your-change` or `feat/your-change`
3. Make changes
4. Update `CHANGELOG.md` under an `[Unreleased]` section
5. Bump version in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
6. Open a PR with a clear description of what changed and why

---

## Reporting issues

Open a GitHub issue with:
- Which phase the problem occurred in
- What the agent did vs what you expected
- The feature request you were working on (summarised)
- Whether you were in worktree or inline mode
- Which settings were enabled
