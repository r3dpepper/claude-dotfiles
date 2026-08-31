# Branch & PR Workflow

Companion to `git-workflow.md`. That file covers commit hygiene
(format, what to commit, force-push bans). This file covers the
end-to-end flow: branch → work → PR → merge.

## Default: squash-merge flow

For every change, no matter how small:

1. **Branch from a fresh main.** Fetch first so you're branching
   from the latest commit, not a stale local main.
   ```bash
   git fetch origin
   git switch -c feature/<short-name> origin/main
   ```
   Branch name: `feature/<thing>`, `fix/<thing>`,
   `chore/<thing>`, or `refactor/<thing>`. Match the commit's
   `type:` prefix so branch and squash-commit line up.

2. **Commit in logical chunks.** Multiple commits are fine —
   they help you bisect and revert mid-work, and the reviewer
   sees them in the PR diff. Don't pre-squash; let the PR
   squash happen on merge.

3. **Push and open a PR.**
   ```bash
   git push -u origin feature/<short-name>
   gh pr create --fill
   ```
   `gh pr create --fill` builds the PR body from the commit
   history. Add a one-line summary at the top if `--fill`
   misses the *why*.

4. **Merge with GitHub's "Squash and merge" button.** After the
   squash:
   - `main` gets **one** commit per merged PR
   - the squash-commit subject is the PR title
   - the PR body becomes the squash-commit body
   - per-commit history stays in the PR, not on `main`
   - `main` stays bisectable by PR, not by individual commit

5. **Delete the feature branch** on the GitHub PR page. Then
   locally:
   ```bash
   git switch main && git pull --ff-only
   git branch -d feature/<short-name>
   git remote prune origin
   ```

## Alternative: rebase then merge

Use this when the work is non-trivial and the per-commit history
on `main` is valuable (e.g. the commits are already well-shaped
with logical checkpoints, and you specifically want `git log` on
`main` to tell the full story).

1. **Branch and commit** as in the default flow.
2. **Before opening the PR (or after addressing review), rebase
   onto main** so the diff is clean:
   ```bash
   git fetch origin
   git rebase origin/main
   git push --force-with-lease
   ```
3. **Open the PR.** In the PR description, note that the branch
   is rebased and the merge should be a regular merge commit,
   not a squash.
4. **Merge with "Create a merge commit"** in the GitHub UI.
   - `main` gets one merge commit (no fast-forward)
   - the merge commit points at the feature branch's tip
   - every feature-branch commit is visible on `main`
5. **If the rebase produced conflicts** that aren't worth
   resolving, fall back to squash-merge. GitHub's UI lets you
   switch.

## When to use which

- **Default to squash-merge.** 95% of the time, one commit per
  PR is the right shape. `main` history stays skimmable, the
  squash-commit message becomes the durable record, and bisect
  on `main` still works at PR granularity.
- **Rebase-merge when**: the work is large, the per-commit
  history is already well-structured, and you want `git log`
  on `main` to tell the full story (multi-day refactor,
  experiment with dead ends kept for the record).
- **Never fast-forward to main without a PR.** The
  `block-main-commit.sh` hook enforces this anyway, but the PR
  is where review happens regardless.

## Branch hygiene

- **One feature branch per PR.** Don't stack unrelated work on
  the same branch — if the PR review pivots, the extra work
  gets stuck.
- **Keep branches short-lived.** Long-lived branches are where
  merge conflicts breed. If a branch is more than a few days
  old, rebase it onto `main` daily.
- **Force-push only with `--force-with-lease`, and only on
  your own feature branch.** The `block-force-push.sh` hook
  denies `--force`/`-f` and asks on `--force-with-lease` —
  so when the hook prompts, that's the safe form.
- **No commits to main directly.** The
  `block-main-commit.sh` hook blocks it regardless, but treat
  it as a discipline even if the hook is disabled.

## When the user overrides the default

- "Just push it" / "skip the PR" → ask before doing it. The
  `block-main-commit.sh` hook will block direct commits to
  `main`; bypassing the hook for a one-off is the user's call,
  not yours.
- "Plan first" → run `/plan`, get approval, then follow this
  workflow.
- "Small fix" → still use the workflow. A 1-line fix in a PR
  is easier to revert than a 1-line fix on `main`.

## Why

The discipline of "feature branch + squash-merge" gives you:

- **`main` that's safe to bisect** at PR granularity
- **Each merged PR is one atomic change** in `git log`, with a
  well-shaped message
- **Work in progress stays private** to the feature branch
- **History is preserved in the PR** even after squash, so
  the per-commit reasoning isn't lost
