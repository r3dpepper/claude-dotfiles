---
name: plan
description: Restate the task, surface risks, and produce a step-by-step plan. WAIT for user approval before touching any code. Never runs inline edits.
when_to_use: |
  Use only when the user explicitly asks to plan, design, or scope
  work before implementation. Trigger phrases: "/plan", "plan this",
  "scope this", "make a plan", "design before coding", "what's the
  approach", "let's plan first". Do NOT auto-load for general work
  or for any request that ends in "just do it" or "skip the plan".
argument-hint: "[feature description]"
disable-model-invocation: true
metadata:
  origin: claude-dotfiles
---

# /plan

Create an implementation plan and **wait for explicit user approval** before
writing any code. This skill never runs inline edits.

## Inputs

$ARGUMENTS

## Process

1. **Restate the request** in your own words. If anything is ambiguous,
   ask. Do not invent requirements.
2. **Ground the plan in the codebase** if one exists. Search for the
   patterns the new code should mirror (naming, error handling, logging,
   tests). Cite file:line for each.
3. **Break the work into ordered tasks**. Each task should be small
   enough to verify on its own.
4. **Identify risks** with likelihood + mitigation. Don't list every
   theoretical risk; focus on the two or three that would actually hurt.
5. **Estimate complexity** (Small / Medium / Large) based on files
   touched and ambiguity.
6. **Present the plan** and **WAIT for the user to confirm** before
   any other action. Do not run Bash, Edit, or Write until they say
   so.

## Output format

```
# Plan: <Feature name>

**Complexity:** Small | Medium | Large
**Files expected to change:** <count>

## Requirements (restated)
- ...

## Patterns to mirror
| Category | Source | Pattern |
|---|---|---|
| Naming | path:line | ... |
| Errors | path:line | ... |
| Tests | path:line | ... |

## Tasks
1. <task 1> — validate: <command>
2. <task 2> — validate: <command>
3. ...

## Risks
- **<risk>** (likelihood) — mitigation: ...

## Validation
- <command that proves the whole change works>

## Acceptance
- [ ] All tasks complete
- [ ] Validation command exits 0
- [ ] Patterns mirrored, not reinvented
```

## When to use

- Starting a new feature
- Multi-file refactor
- Architectural change
- Work where requirements are unclear
- Anything you'll be reviewing later

## When NOT to use

- One-line fix obvious from the error message
- Reading / explaining existing code (use AskUserQuestion or just answer)
- User said "just do it" — skip the plan
