---
description: Invoke the code-review skill to handle incoming review feedback from a human reviewer or PR comments. Categorises feedback, addresses required and requested changes, and writes a PR reply summary.
disable-model-invocation: true
---

Invoke the `code-review` skill.

Read all feedback first. Categorise each comment as Required / Requested / Discussion / Nitpick. Confirm any Discussion items before implementing. Fix all Required and Requested items, run tests, and write a PR reply summary.
