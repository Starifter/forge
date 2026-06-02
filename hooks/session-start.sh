#!/bin/bash
# Injects the using-forge enforcement context at session start.
# Runs synchronously before the first agent turn.

SKILL_PATH="${CLAUDE_PLUGIN_ROOT}/skills/using-forge/SKILL.md"

if [ ! -f "$SKILL_PATH" ]; then
  exit 0
fi

# Read the skill content (strip YAML frontmatter)
CONTENT=$(awk '/^---/{found++; next} found>=2{print}' "$SKILL_PATH")

# Emit Claude Code format
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $(echo "$CONTENT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")
  }
}
EOF
