# Hooks

## SessionStart hook

**Files:** `hooks.json`, `session-start.sh`

The SessionStart hook fires at the start of every Claude Code session, before the first agent turn. It reads `skills/using-forge/SKILL.md`, strips the YAML frontmatter, and injects the enforcement rules as additional context.

This means the 1% rule, the gate table, and the rationalisations list are always present from the very first message — not just when a task triggers the main `forge` skill.

### How it works

`hooks.json` registers the hook:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

`session-start.sh` reads the skill file and outputs the required JSON format:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "..."
  }
}
```

### Troubleshooting

If the enforcement context isn't appearing at session start:

```bash
# Check the script is executable
ls -la ~/.claude/skills/forge/hooks/session-start.sh

# Make it executable if not
chmod +x ~/.claude/skills/forge/hooks/session-start.sh
```

Then restart Claude Code.
