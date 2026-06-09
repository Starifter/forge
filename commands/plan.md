---
description: Jump directly to the Plan phase of the forge. Assumes Spec and Worktree are already complete. Produces a task list grouped into parallel-safe waves and waits for user approval.
disable-model-invocation: true
---

Invoke the `forge` skill and start at **Phase 4: Plan**.

**Resolve the feature folder first:**
```bash
ls -d .forge/*/ 2>/dev/null
```
- None → there's nothing to plan from yet; tell the user to start at `/forge:spec`.
- Exactly one → use it.
- Multiple → use AskUserQuestion to let the user pick which feature folder to plan.

Pass the chosen folder to the plan-agent as `Feature folder: .forge/<name>/`. Then produce an implementation plan with atomic tasks (2–5 minutes each) grouped into waves. Read `references/planning-guide.md` first. Present the plan and wait for user approval before continuing.
