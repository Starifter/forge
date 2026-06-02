# Contributing to Forge

Thanks for wanting to improve Forge. This guide covers how the plugin is structured, how to test changes, and how to submit them.

---

## Structure

```
forge/
├── .claude-plugin/plugin.json   # Name, version, hook reference
├── agents/                      # One .md file per agent
├── commands/                    # One .md file per slash command
├── hooks/                       # SessionStart hook
└── skills/                      # Skill directories (SKILL.md + references/)
```

**Agents** are the workers. Each one has a YAML frontmatter block (`name`, `description`, `model`, `effort`, `maxTurns`) and a Markdown body with instructions.

**Skills** are the orchestrators. `skills/forge/SKILL.md` is the main workflow. `skills/using-forge/SKILL.md` is the enforcement meta-skill. `skills/code-review/SKILL.md` handles PR review responses.

**Commands** are thin wrappers that invoke a skill or agent phase. They use `disable-model-invocation: true` so they're user-only.

---

## Making changes

### Changing a phase's behaviour
Edit the relevant agent `.md` file in `agents/`. The agent's `description` field controls when Claude invokes it automatically — keep it specific and honest.

### Changing orchestration logic
Edit `skills/forge/SKILL.md`. This is the main workflow file. Be careful with the HARD GATE sections — they're what prevents Claude from skipping steps.

### Changing enforcement rules
Edit `skills/using-forge/SKILL.md`. This is injected at every session start via the hook.

### Adding a new agent
1. Create `agents/your-agent.md` with YAML frontmatter and instructions
2. Reference it by name in the relevant SKILL.md phase using the Agent tool pattern
3. Test that the orchestrator invokes it correctly

### Adding a new slash command
1. Create `commands/your-command.md` with frontmatter including `disable-model-invocation: true`
2. Write a brief instruction body that redirects to the relevant skill/phase

---

## Principles to maintain

**Hard gates are non-negotiable.** Every user-facing decision goes through `AskUserQuestion`. Every phase has an explicit gate. Do not add "optional" steps that can be silently skipped.

**The orchestrator never codes.** `skills/forge/SKILL.md` invokes agents — it never implements anything directly. Keep this separation clean.

**Fresh context per task.** `task-implementer` prompts should include only: the task, the target file, and conventions. Do not pass full conversation history or the entire plan.

**Wave-level batch review.** Reviewers fire per wave, not per task. Don't revert this — it's a meaningful speed improvement with no quality loss.

**Haiku for mechanical work.** `researcher` runs on Haiku because it's doing file reading and pattern extraction, not reasoning. If you add agents for similarly mechanical tasks (e.g. summarising, searching), use Haiku.

---

## Testing

Install the plugin locally:

```bash
claude /install forge.skill
```

Test the full workflow on a real small feature in a test repo. Check that:
- `AskUserQuestion` fires at every gate (not plain text questions)
- Worktree setup runs in background and doesn't block Research
- Wave classification logs correctly (Fully parallel / Mixed / Fully sequential)
- Batch review fires per wave, not per task
- The `using-forge` enforcement context appears at session start

---

## Submitting changes

1. Fork the repo
2. Create a branch: `git checkout -b fix/your-change` or `feat/your-change`
3. Make your changes
4. Update `CHANGELOG.md` under an `[Unreleased]` section
5. Open a PR with a clear description of what changed and why

---

## Reporting issues

Open a GitHub issue with:
- What phase the problem occurred in
- What the agent did vs what you expected
- The feature request or task you were working on (summarised is fine)
