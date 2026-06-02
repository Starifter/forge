# Planning Guide

Detailed guidance for the Plan phase of the forge skill.

---

## What makes a good task

A task is a single, atomic unit of work:
- **Completable in 2–5 minutes** — if longer, split it
- **Tied to a specific file** — every task names an exact path
- **Unambiguous** — someone reading it cold knows exactly what to do
- **Testable** — clear when done

**Good:** `Task 2.3: Add validateEmail() helper → src/utils/validation.ts`
**Bad:** `Task 2.3: Handle email validation`

---

## Wave grouping rules

Tasks with no shared file dependencies → same wave (parallel-safe)
Task B depends on Task A's output → different waves (A first)
When unsure → separate waves (safer, low cost)

**Parallel-safe (same wave):**
- Add `UserCard` component → `src/components/UserCard.tsx`
- Add `formatDate()` util → `src/utils/date.ts`

**Must be sequential (different waves):**
- Wave 1: Create `src/services/auth.ts` with `AuthService` class
- Wave 2: Import `AuthService` in `src/app.ts`

---

## Wave labels

- Wave 1 — Foundation (new files, types, interfaces)
- Wave 2 — Core Logic (primary implementation)
- Wave 3 — Integration (wiring together)
- Wave 4 — Tests
- Wave 5 — Cleanup (docs, linting)

---

## Sizing

- **Tiny (1–3 tasks):** No wave structure needed, just number them
- **Small (4–8 tasks):** 2–3 waves
- **Medium (9–20 tasks):** 3–5 waves
- **Large (20+ tasks):** Flag to the user, suggest splitting into phases

---

## Common mistakes

- Tasks that do too much: "Implement the entire auth system" is not a task
- Tasks with no file reference
- Wave 1 tasks with internal dependencies
- Missing test tasks — always include them explicitly
- Over-planning: a 2-line change doesn't need 5 tasks
