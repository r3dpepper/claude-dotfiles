#!/usr/bin/env bash
# PreToolUse:Bash — deny force-push; ask on --force-with-lease (the safe form).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
cmd="$(get_cmd)"
tool="$(get_tool)"

[ "$tool" = "Bash" ] || exit 0
contains_git_push "$cmd" || exit 0

# 1. Hard-deny any --force / -f (incl. aliased +branch refspec)
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]].*(--force|-f([[:space:]]|$))'; then
  deny "Force-push is disabled. Use \`git push --force-with-lease\` if you must, or open a PR."
  exit 0
fi

# 2. +refspec force (e.g. `git push origin +main`) — also destructive
if contains_plus_refspec "$cmd"; then
  deny "Push with '+' refspec (force) is disabled. Use --force-with-lease if you must, or open a PR."
  exit 0
fi

# 3. --force-with-lease: ask (safe-ish but still worth confirming)
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]].*--force-with-lease'; then
  ask "git push --force-with-lease detected. Confirm this is intentional."
  exit 0
fi

exit 0
