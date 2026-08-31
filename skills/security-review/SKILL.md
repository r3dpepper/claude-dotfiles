---
name: security-review
description: Run a security-focused review of recent changes. Higher-effort, narrower scope than /code-review. Delegates to the `security-reviewer` subagent.
when_to_use: |
  Use only when the user explicitly asks for a security review.
  Trigger phrases: "/security-review", "security check this",
  "audit for vulnerabilities", "review for security", "is this
  safe", "check the auth changes". Do NOT auto-load for general
  code review — use /code-review instead.
argument-hint: "[path-or-commit-range]"
disable-model-invocation: true
metadata:
  origin: claude-dotfiles
---

# /security-review

Focused security pass on recent changes. Higher-effort, narrower scope
than `/code-review` — this is a deep dive for changes that touch
auth, secrets, network, file I/O, or untrusted input.

## Inputs

$ARGUMENTS

## When to use

- Touched authentication or session handling
- Added or modified a network call
- Wrote or changed a database query
- Handled user-supplied files or paths
- Modified crypto, signing, or token logic
- About to ship a change that the user flagged as "security sensitive"

If the change is small and clearly safe (docs, formatting, internal
refactor), use `/code-review` instead.

## Process

1. **Determine scope** using the same rules as `/code-review`.
2. **Invoke the `security-reviewer` subagent** with the scope.
3. **Treat every CRITICAL or HIGH finding as a blocker.** Do not move
   on to the next task until they're resolved.
4. **For each finding, recommend a concrete fix** with a file:line and
   a short rationale. The user will approve before you apply anything.
5. **Summarize** with the count by severity and the actions taken.

## Output format

```
# Security Review: <scope>

## Scope
- <files / range>

## Findings by severity
### CRITICAL (blockers)
- <file:line> — <issue> → <proposed fix>

### HIGH (fix before merge)
- <file:line> — <issue> → <proposed fix>

### MEDIUM (note for follow-up)
- <file:line> — <issue>

### LOW (informational)
- <file:line> — <issue>

## What I changed
- <file:line> — <what was done>

## What needs the user's call
- <file:line> — <options A / B / C>

## Summary
<verdict: APPROVE / CHANGES REQUIRED / BLOCK>
```

## What the `security-reviewer` agent checks

The full checklist is in the agent's body. High-level categories:

- **Secrets & credentials**: hardcoded, logged, exposed in error
  messages
- **Input validation**: missing length limits, type checks, encoding
- **Injection**: SQL, shell, template, path traversal
- **Auth & authz**: missing checks, IDOR, privilege escalation
- **Cryptography**: weak primitives, missing randomness, predictable
  IDs
- **Dependencies**: known-vulnerable versions
- **Network**: TLS, certificate validation, open redirects
