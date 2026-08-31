---
name: commit-message
description: Writes a structured Conventional Commits message from the current git diff and prints it for the user to confirm. Does NOT run `git commit` itself.
when_to_use: |
  Use only when the user explicitly asks to commit, write a commit message,
  draft a commit, or "stage and commit". Trigger phrases: "commit this",
  "write a commit message", "draft a commit", "stage and commit", "/commit".
  Do NOT load this skill for general file editing, code review, or any
  task that doesn't end in a commit.
disable-model-invocation: true
context: fork
allowed-tools: Bash(git diff*), Bash(git status*), Bash(git log*)
metadata:
  origin: claude-dotfiles
---

# Commit Message

## Current state

!`git diff --staged`
!`git diff`

## Instructions

You are in a forked context. The diff above is inlined — do not run `git diff`
again. Your job is to **produce the commit message** and stop. Do not run
`git commit`, `git add`, or any state-changing command.

### Format

```
<type>(<scope>): <subject>

<body — bulleted, grouped by file or area>

<footer — refs, breaking changes>
```

- **type**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`,
  `build`, `ci`, `style` (Conventional Commits).
- **scope**: optional, the area affected (`api`, `auth`, `ui`, `hooks`,
  `installer`). Omit if cross-cutting.
- **subject**: imperative mood, lowercase first word, no period,
  ≤ 72 chars. "Add", "Fix", "Refactor", "Remove" — not "Added",
  "Fixes", "Refactoring".
- **body**: bullets grouped by file or area, not by line number. Each
  bullet starts with a verb. If you change 12 lines in 4 files, write
  4 bullets — one per file — not 12.
- **footer**: `Refs: #123` / `Closes: #456` for tickets.
  `BREAKING CHANGE: <what and why>` if applicable.

### Derivation

1. If both diffs are empty, return "Nothing to commit." and stop.
2. Read the diff. Group changes by file or area (config, docs, tests,
   source).
3. The primary change is the subject. Everything else goes in the body.
4. Pick the right `type`:
   - `feat:` — new user-visible behavior
   - `fix:` — bug fix
   - `refactor:` — restructuring without behavior change
   - `chore:` — tooling, build, ci
   - `docs:` — docs only
   - `test:` — test-only
   - `revert:` — reverts a prior commit (include the SHA)

### Examples

**Single-file bug fix**

```
fix(auth): reject expired tokens in middleware

- auth/middleware.ts: check `exp` claim before trusting the token
  and return 401 on expiry instead of 500.

Refs: #234
```

**Cross-cutting refactor**

```
refactor(installer): split link_file into a separate module

- lib/common.sh: extract link_file from install.sh into a
  reusable helper.
- install.sh: source the new helper instead of redefining.

Reduces install.sh from 90 lines to 30 and lets bootstrap.sh use
the same helper.
```

**New feature**

```
feat(skills): add commit-message and tdd-workflow skills

- skills/commit-message/SKILL.md: structured commit format with
  Conventional Commits.
- skills/tdd-workflow/SKILL.md: red-green-refactor procedure.
- install.sh: symlink skills/ directory into ~/.claude/skills/.
```

### Anti-patterns

- ❌ "Update file.ts" — restates the filename, no information
- ❌ "Various improvements" — meaningless
- ❌ Long prose paragraphs in the body — use bullets
- ❌ Co-authored-by / Signed-off-by in the *message* — those are
  trailers, not human-readable content
- ❌ Mentioning Claude or the AI in the message — the author is the
  human, not the tool

### Why

A commit message is the cheapest documentation you'll ever write. The
`git log` is the first place a new contributor (or future-you) goes to
understand a codebase. Spend 30 seconds making it useful.
