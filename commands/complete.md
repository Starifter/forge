---
description: Jump to the Complete phase of the forge. Assumes Verify has passed. Delivers a summary of what was built and offers merge/PR options (GitHub PR, local merge, keep open, or clean up worktree).
disable-model-invocation: true
---

Invoke the `forge` skill and start at **Phase 8: Complete**.

**Resolve the feature folder first:**
```bash
ls -d .forge/*/ 2>/dev/null
```
- None → there's no session to complete; tell the user nothing is in progress.
- Exactly one → use it.
- Multiple → use AskUserQuestion to let the user pick which feature folder to complete.

Using that folder, deliver the completion summary (what was built, files changed, tests passed, branch name) and write `.forge/<name>/complete.md`. Then offer the four finish options: open a GitHub PR, merge locally, keep the branch open, or just clean up the worktree.
