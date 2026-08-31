#!/usr/bin/env bash
# PreToolUse:Bash — hard-block any `git commit` when current branch is main/master.
# Runs even if the user has a `Bash(git commit *)` allow rule, because hooks
# intercept the tool call before permission rules are evaluated.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
cmd="$(get_cmd)"
tool="$(get_tool)"

# Only act on Bash + git commit
[ "$tool" = "Bash" ] || exit 0
contains_git_commit "$cmd" || exit 0

# Need a git repo to determine branch
in_git_repo || exit 0
branch="$(get_branch)"

case "$branch" in
  main|master)
    deny "Refusing to commit directly to '$branch'. Create a feature branch (e.g. \`git switch -c feat/your-change\`) and commit there, then open a PR."
    ;;
esac

exit 0
