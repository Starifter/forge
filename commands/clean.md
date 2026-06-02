---
description: Remove .forge session files. Without arguments, lists all feature folders and asks which to clean. Pass a feature name to clean a specific one, or "all" to wipe the entire .forge/ directory.
disable-model-invocation: true
---

Clean up `.forge/` session files.

**If the user ran `/forge:clean` with no argument:**

```bash
ls .forge/ 2>/dev/null
```

If `.forge/` is empty or doesn't exist:
```
Nothing to clean — no .forge/ session files found.
```

If feature folders exist, use AskUserQuestion:
```
AskUserQuestion:
  question: "Which .forge/ session would you like to remove?"
  options: [each folder name listed from ls .forge/, "All of them", "Cancel"]
```

Then run the appropriate command:

**Specific feature:**
```bash
rm -rf ".forge/[selected-feature-name]/"
echo "✅ .forge/[feature-name]/ removed."
```

**All:**
```bash
rm -rf .forge/
echo "✅ .forge/ fully removed."
```

**If the user passed a feature name directly** (e.g. `/forge:clean add-user-auth`):
```bash
rm -rf ".forge/[feature-name]/"
echo "✅ .forge/[feature-name]/ removed."
```

**If the user passed "all":**
```bash
rm -rf .forge/
echo "✅ .forge/ fully removed."
```
