# Subagent Instructions

How to construct, dispatch, and review subagents in the Implement phase.

---

## Why fresh subagents per task

Long context degrades judgment. A subagent starting clean — with only its task and minimal context — produces better output than one carrying the full session history. The coordinator manages sequencing and review; subagents just implement.

---

## Subagent prompt structure

Include exactly these things — no more:

1. **The task** — copied verbatim from the plan
2. **Relevant existing code** — only the file being edited, or the interface it must conform to. Not unrelated files, not the full plan.
3. **Coding conventions** — 1–2 bullets from Research if applicable
4. **Output report** — "Report what you changed, any deviations, and any assumptions"

**Keep prompts under ~3,000 tokens.** If the relevant file is large, paste only function signatures and types, not implementations.

---

## Example prompt

```
Task: Add validateEmail() helper → src/utils/validation.ts

Current file:
---
export function validateRequired(value: string): boolean {
  return value.trim().length > 0;
}
---

Add validateEmail(email: string): boolean using a standard regex. No external libraries.

Conventions:
- Named exports only

Report what you changed and any assumptions made.
```

---

## Two-stage review checklist

**Stage 1 — Spec compliance:**
- [ ] Task from the plan is fully implemented
- [ ] Correct file was edited
- [ ] No files outside task scope were touched
- [ ] Output matches the plan's intent

**Stage 2 — Code quality:**
- [ ] No obvious bugs (unhandled edge cases, missing null checks)
- [ ] Follows patterns from Research (naming, structure, error handling)
- [ ] No dead code, commented-out blocks, or unused imports
- [ ] Simplest solution that works

**On Stage 1 failure:** Restate the task clearly and specify what's missing. Re-run.
**On Stage 2 failure:** Describe the quality issue and the pattern it should follow instead. Re-run.

---

## Parallel execution: conflict check

Before launching a wave in parallel:
1. List every file each task will write to
2. Two tasks writing to the same file → run them sequentially within the wave
3. No overlap → launch simultaneously

Don't start Wave N+1 until all Wave N tasks have passed both review stages.
