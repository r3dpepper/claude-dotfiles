---
name: code-review
description: Run a code review of recent changes. Reads the diff, invokes the `code-reviewer` subagent, and triages findings. Use after writing or modifying code, before committing.
when_to_use: |
  Use only when the user asks for a code review. Trigger phrases:
  "/code-review", "review this", "review my changes", "review the
  diff", "check this code", "what do you think of these changes".
  Do NOT auto-load for general editing or after every Edit tool call.
argument-hint: "[path-or-commit-range]"
disable-model-invocation: true
metadata:
  origin: claude-dotfiles
---

# /code-review

Run a focused review of recent changes. Delegates to the `code-reviewer`
subagent for the actual review pass, then triages findings in the main
session.

## Inputs

$ARGUMENTS

## Process

1. **Determine scope.**
   - If `$ARGUMENTS` looks like a path (`src/api/...`), review that path.
   - If it looks like a ref/range (`HEAD~3..HEAD`, `abc123..def456`),
     review that range.
   - Otherwise, review the working tree (`git diff` and
     `git diff --staged`).

2. **Show the user what you're about to review.** Print the diff stats
   and the file list. Wait if the scope looks wrong.

3. **Delegate to the `code-reviewer` subagent** with the scope as a
   constraint. The agent runs in its own context window — only its
   summary returns.

4. **Triage the agent's findings in the main session.** For each
   finding, decide:
   - **Act now** — real bug, fix it before continuing
   - **Note for follow-up** — real issue but out of scope for this
     change
   - **Drop** — false positive, stylistic preference, or below
     confidence threshold

5. **Report back** with the triaged list and the actions taken.

## Output format

```
# Code Review: <scope>

## Scope
- <files / range reviewed>

## Findings (triaged)
### Acted on
- <file:line> — <what was wrong, what I did>

### Noted for follow-up
- <file:line> — <what's wrong> (out of scope for this change)

### Dropped
- <file:line> — <reason: false positive / nit / below confidence>

## Summary
<one paragraph: overall quality, any blockers, suggested next step>
```

## What the `code-reviewer` agent checks

- Security (CRITICAL): hardcoded secrets, SQL injection, XSS, path
  traversal, auth bypasses
- Code quality (HIGH): mutation, unhandled errors, deep nesting,
  large functions
- Test gaps: changed code without a corresponding test
- Convention violations: doesn't match patterns in the same directory
