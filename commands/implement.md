---
description: Jump directly to the Implement phase of the forge. Assumes an approved plan exists. Ask the user for sequential or parallel execution, then dispatch subagents per task with two-stage review after each.
disable-model-invocation: true
---

Invoke the `forge` skill and start at **Phase 5: Subagent Flow**.

**Resolve the feature folder first:**
```bash
ls -d .forge/*/ 2>/dev/null
```
- None → there's no approved plan; tell the user to start at `/forge:spec` or `/forge:plan`.
- Exactly one → use it.
- Multiple → use AskUserQuestion to let the user pick which feature folder to implement.

Pass the chosen folder to every subagent as `Feature folder: .forge/<name>/`. Then ask the user: sequential or parallel execution? Execute the approved plan — fresh subagent per task, two-stage review (spec compliance + code quality) **batched per wave** (or after each task if `strict_wave_review` is enabled), marking tasks ✅ as they pass.
