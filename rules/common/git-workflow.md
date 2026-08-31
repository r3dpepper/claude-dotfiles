# Git Workflow

Applies to all projects unless a project's own `.claude/rules/` overrides.

## Branches

- **Never commit directly to `main` or `master`.** Always work on a feature
  branch (`feat/...`, `fix/...`, `chore/...`, `refactor/...`).
  *Why:* direct commits to main bypass review and break bisect.
- Branch from a fresh `main` whenever possible. Rebase before merging
  to keep history linear.
- One logical change per branch. Squash noisy WIP commits before review.

## Commits

- Write commit messages in the imperative mood
  ("Add user search", not "Added" or "Adds").
- First line ≤ 72 characters. Blank line, then optional body wrapped at
  72 chars. The `/commit` command enforces a structured format.
- Reference the issue/ticket ID in the footer (`Refs: #123`,
  `Closes: #456`) when one exists.
- Don't commit: secrets (see security.md), generated files
  (build artifacts, `node_modules`, `dist/`), debug prints,
  commented-out code, half-finished work.

## Pushes

- **No force-push** to shared branches. Use `git push --force-with-lease`
  only on your own branch, and only after a rebase.
  *Why:* force-push rewrites history that collaborators may have
  already pulled. `--force-with-lease` at least catches the
  "someone else pushed while you weren't looking" case.
- Prefer **pull requests over direct pushes** to `main`. CI should run
  before merge.

## Remotes

- Never add an unrelated remote. If a repo has `origin` and `upstream`,
  leave them both; don't add a third without asking.
- Forks stay forks — don't push to the upstream repo directly.

## When in doubt

- If a git operation is destructive (`reset --hard`, `clean -fd`,
  `checkout -- .`), **ask the user** before running it. The
  `block-destructive.sh` hook enforces this.
- If you don't know which branch you're on, run `git status` and
  `git branch --show-current` before anything else.

## End-to-end flow (branch → work → PR → merge)

For the full workflow — when to branch, when to rebase vs.
squash-merge, how to handle review — see
[`branch-workflow.md`](./branch-workflow.md). This file covers
commit hygiene; that file covers the PR-shaped workflow.
