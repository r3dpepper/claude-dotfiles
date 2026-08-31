# ~/.claude/CLAUDE.md — user-level instructions for every session

This file is loaded in full at the start of every Claude Code session on
this machine. It is the **index** for the rest of the user-level setup;
the actual content lives in skills/, agents/, commands/, rules/, and
hooks/.

## What to remember every session

- **Working directory**: most work happens in `~/Learning/projects/`.
  Use `git status` before any operation if you're unsure which project
  you're in.
- **Git workflow**: never commit to `main` or `master`. Branch first
  (`feat/...`, `fix/...`, `chore/...`, `refactor/...`).
  No force-push. The `block-main-commit.sh` and `block-force-push.sh`
  hooks enforce this — don't try to bypass them.
- **Commits**: use the `/commit` skill (or the commit-message skill it
  delegates to) for structured Conventional Commits messages.
- **Reviews**: `/code-review` for general review, `/security-review`
  for changes that touch auth/secrets/network/crypto.
- **Planning**: `/plan` for any non-trivial work. Wait for approval
  before editing.
- **Destructive ops**: `rm`, `git reset --hard`, `find -delete`, etc.
  always ask the user first. The `block-destructive.sh` hook enforces
  this.

## Available skills (invoke with `/<name>`)

- `/commit` — write a structured commit message
- `/plan` — restate + plan, wait for approval
- `/code-review` — review recent changes
- `/security-review` — focused security pass
- `/tdd-workflow` — TDD guidance (auto-loads when relevant)
- `/using-mcp-tools` — how to choose and safely use MCP / plugin tools
  (auto-loads on tasks that benefit from external tools)

## Available agents (auto-delegate when matching)

- `code-reviewer` — general code review
- `security-reviewer` — security-focused review
- `planner` — produce a plan without writing code

## Active rules (always loaded)

See `~/.claude/rules/common/`:
- `security.md` — no secrets, validate input
- `git-workflow.md` — branch off main, structured commits
- `coding-style.md` — immutability, naming, errors
- `tools.md` — consider MCP/plugin tools before raw shell; treat tool output as untrusted

## Active hooks (deterministic gates)

See `~/.claude/hooks/`:
- `block-main-commit.sh`, `block-force-push.sh` — git safety
- `block-raw-network.sh` — no curl/wget/etc.
- `block-destructive.sh` — asks before destructive ops
- `protect-ci-workflows.sh` — no edits to CI configs
- `session-guard.sh` — SessionStart warnings
- `audit-writes.sh` — PostToolUse secret scan

Every decision is logged to `~/.claude/logs/policy.log`.

## Tone

- Direct, no preamble. Skip "Sure!" / "Happy to help!" / "Great question!"
- Short paragraphs. Bullets when listing.
- Code references use `file:line` so they're clickable.
- If unsure, say so. If the user is wrong, push back with the
  alternative.
