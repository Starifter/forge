# Spec Dialogue (run inline by the orchestrator)

The Spec phase is **interactive** — it is a back-and-forth dialogue with the user, so it runs in the orchestrator (the main loop), never in a subagent. Subagents cannot ask the user questions. Follow this procedure directly in Phase 1.

**Always use the AskUserQuestion tool for every question — including the final confirmation. Never ask questions as plain text.**

---

## Dialogue structure

Ask questions in rounds. Each round focuses on one topic, 3–5 questions max, asked one at a time with AskUserQuestion. Synthesise what you've learned after each round. Stop asking when you can write a complete, unambiguous design document.

### Round 1 — Scope & Intent
Draw from:
- "What problem does this solve, and who experiences it?"
- "What does success look like — how will you know it's working?"
- "Is this a new feature, a change to existing behaviour, or a fix?"
- "Are there existing parts of the codebase this touches or replaces?"
- "Any deadline, performance, or scale requirements worth knowing upfront?"

Example:
```
AskUserQuestion:
  question: "Is this a new feature, a change to existing behaviour, or a fix?"
  options: ["New feature", "Change to existing behaviour", "Bug fix", "Refactor", "Other"]
```

### Round 2 — Behaviour & Edge Cases
- "What happens when [the main thing] fails or is unavailable?"
- "What are the boundary conditions? (empty input, max size, concurrent access)"
- "Are there different user roles or permissions that affect behaviour?"
- "What should NOT change — things that must stay exactly as they are?"

### Round 3 — Constraints & Integration
Only ask if the feature has meaningful constraints:
- "Are there specific libraries or APIs this must use or avoid?"
- "Any security, privacy, or compliance requirements?"
- "Any performance requirements? (latency, throughput, memory)"
- "Does this integrate with other systems?"

### Round 4 — Validation (if needed)
Up to 3 final clarifications via AskUserQuestion. Only for genuine blockers.

---

## When to stop asking

Stop when you can answer yes to all:
- [ ] I know what is being built and why
- [ ] I know how it behaves in the happy path
- [ ] I know what happens in the main failure and edge cases
- [ ] I know what constraints the solution must respect
- [ ] I could write the acceptance criteria without guessing

---

## Write the design document

Once you have enough, write the design document to `.forge/[feature-name]/spec.md`:

```bash
cat > ".forge/[feature-name]/spec.md" << 'SPECEOF'
# Spec: [Feature Name]

## Problem
[1–2 sentences: what problem this solves and for whom]

## What's being built
[2–3 sentence description in plain language]

## Scope
### In scope
- [concrete deliverable 1]
- [concrete deliverable 2]

### Out of scope
- [explicitly deferred or excluded]

## Behaviour
### Happy path
[step-by-step description of normal operation]

### Edge cases & error handling
- [edge case]: [expected behaviour]

## Constraints
- [constraint 1]

## Acceptance criteria
- [ ] [specific, testable, unambiguous condition]
- [ ] [specific, testable, unambiguous condition]

## Open questions for planning
- [anything the planner should decide, not block on]
SPECEOF
```

If a UI Check ran first, fold the confirmed `ui-spec.md` direction into the relevant sections.

---

## Confirmation gate

After writing the file, use AskUserQuestion:

```
AskUserQuestion:
  question: "Design document written to .forge/[feature-name]/spec.md. Does this look right?"
  options: ["Yes, looks good — proceed to workspace setup", "I have changes to make", "Other"]
```

If changes requested: update `.forge/[feature-name]/spec.md` and re-confirm. Do not proceed until confirmed.

**Tiny task shortcut:** Single file, zero ambiguity → skip all rounds, write the spec directly, still confirm.
