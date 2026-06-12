---
name: using-forge
description: >
  Process enforcement skill. Injected at every session start. Ensures forge
  is always invoked for coding tasks and that every HARD GATE is honoured.
  Trigger on session start and on any message containing implementation intent.
---

# Using Forge

## The 1% Rule

Before responding to any message: "Is there even a 1% chance this involves writing or changing code?"

If yes — invoke `forge`. Do this before clarifying questions, before research, before anything.

---

## The 5 Hard Gates — never skip any of them

| Gate | After phase | What you MUST do before proceeding |
|---|---|---|
| Gate 1 | Spec | Spec dialogue runs inline (in the main loop); do not proceed until the user confirms the spec |
| Gate 2 | Workspace | Ask worktree or inline — if worktree, kick off background setup then immediately begin Plan |
| Gate 3 | Plan | `plan-agent` returns approved plan + execution mode — do not proceed until it does |
| Gate 4 | Before Implement | If worktree mode: check background setup completed + baseline green before dispatching tasks |
| Gate 4B | After Implement | All tasks ✅ or flagged — send completion report + "Shall I run tests?" |
| Gate 5 | Verify | Tests pass — show only finish options relevant to workspace mode |

**Both modes:** YOU are always the orchestrator — no middleman agents for execution. Sequential runs tasks one at a time then batch-reviews each wave. Parallel dispatches tasks simultaneously then batch-reviews each wave. Never start the next wave until the current wave is fully resolved.

**If you have not received a response to the gate message, you are still at that gate.**

---

## Rationalisations to reject

| Rationalisation | Correct response |
|---|---|
| "It's just one line" | Gate 1 → Gate 2 → worktree → Gate 3 still required |
| "User seems in a hurry" | Gates take seconds. Skipping them causes bugs on main |
| "I know they want parallel" | Use AskUserQuestion (Gate 3). Never assume |
| "Tests will obviously pass" | Use AskUserQuestion (Gate 4). Never auto-run |
| "They probably want a PR" | Use AskUserQuestion (Gate 5). Never auto-merge |
| "I'll just ask as plain text" | Always use AskUserQuestion tool. No exceptions. |

---

## If you catch yourself skipping a gate

Stop immediately. Say:

```
I skipped [gate name]. Let me back up.

[send the correct gate message]
```

Do not continue until the user responds to it.
