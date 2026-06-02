---
name: code-review
description: >
  Use this skill when receiving code review feedback from a human reviewer, teammate, or PR comment.
  Handles responding to review feedback without scope creep, defensive changes, or unrelated refactors.
  Trigger whenever someone shares review comments, asks you to "address feedback", "fix PR comments",
  or "respond to review". Also trigger when the user pastes review feedback into the conversation.
---

# Code Review Response

How to receive and respond to code review feedback without common failure modes.

---

## Before touching any code

Read all feedback first. Categorise each comment:

| Category | Definition | Response |
|---|---|---|
| **Required** | Correctness bug, security issue, broken contract | Must fix |
| **Requested** | Style, naming, structure preference from reviewer | Fix unless you have a technical objection |
| **Discussion** | Design question, architectural concern | Respond with reasoning, don't silently implement |
| **Nitpick** | Minor style, reviewer marked optional | Fix if trivial, skip if costly |

Write out your categorisation before implementing anything. Share it with the user if any comment is ambiguous.

---

## Common failure modes — never do these

**Scope creep:** A review comment about a function name is not permission to refactor the whole module. Fix exactly what was asked.

**Defensive changes:** Don't silently add extra validation or error handling that wasn't in the review. If you think it's needed, say so separately.

**Unrelated cleanup:** Don't fix unrelated issues you notice while addressing feedback. Open a separate task.

**Performative agreement:** Don't implement something you think is wrong just to appear agreeable. Say why you disagree — technically, with evidence.

**Over-explaining:** Don't add comments explaining why you made a change. The code should speak for itself. PR reply ≠ inline comment.

---

## Responding to a disagreement

If you believe a reviewer's suggestion would make the code worse:

```
I understand the concern about [X]. My reasoning for the current approach is [Y]:
- [technical reason 1]
- [technical reason 2]

An alternative that addresses your concern while preserving [Z] would be [proposal].
Happy to implement that instead — what do you think?
```

Never silently ignore feedback you disagree with. Never implement something wrong to avoid conflict.

---

## Implementation process

1. **List every comment** with its category (Required / Requested / Discussion / Nitpick)
2. **Get confirmation** on anything categorised as Discussion before implementing
3. **Implement Required and Requested changes** — one at a time, using fresh context per change
4. **Run tests** after all changes — verify nothing regressed
5. **Write a PR reply summary:**

```
Addressed all feedback:

- [comment 1]: [what you did / why you disagreed]
- [comment 2]: [what you did]
- [comment 3]: Left as-is — [reasoning], open to discuss

Tests: X passing, 0 failing
```

---

## What counts as done

- Every Required comment fixed
- Every Requested comment fixed or explicitly discussed
- Every Discussion comment replied to with reasoning
- Tests passing
- PR reply written

Do not re-request review until all of the above are complete.
