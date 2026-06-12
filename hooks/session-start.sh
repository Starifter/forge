#!/bin/bash
# Injects using-forge enforcement context + current Forge settings at session start.

SKILL_PATH="${CLAUDE_PLUGIN_ROOT}/skills/using-forge/SKILL.md"
SETTINGS_PATH="${CLAUDE_PLUGIN_ROOT}/settings.json"

if [ ! -f "$SKILL_PATH" ]; then
  exit 0
fi

# Strip YAML frontmatter from skill
SKILL_CONTENT=$(awk '/^---/{found++; next} found>=2{print}' "$SKILL_PATH")

# Read current settings if available
if [ -f "$SETTINGS_PATH" ]; then
  SETTINGS_CONTENT=$(cat "$SETTINGS_PATH")
else
  SETTINGS_CONTENT='{"pluginConfigs":{"forge":{"options":{"tdd_mode":false,"strict_wave_review":false,"worktree_default":"","auto_clean":false,"verify_per_wave":false,"auto_max_fix_attempts":3}}}}'
fi

# Combine into context
COMBINED="${SKILL_CONTENT}

---

## Current Forge Settings

\`\`\`json
${SETTINGS_CONTENT}
\`\`\`

Apply these settings immediately. If tdd_mode is true, use tdd-task-implementer instead of task-implementer for all implementation tasks."

python3 -c "
import json, sys
content = sys.stdin.read()
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': content
    }
}))
" << PYEOF
$COMBINED
PYEOF
