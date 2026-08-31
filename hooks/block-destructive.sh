#!/usr/bin/env bash
# PreToolUse:Bash — broad destructive-command gate. Each rule ASKs (not denies)
# so legitimate uses still work after confirmation. The `rm` case is already
# handled by your existing hook; this expands coverage.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
cmd="$(get_cmd)"
tool="$(get_tool)"

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

# 1. rm (keep the existing behavior — ask)
if printf '%s' "$cmd" | grep -qE '(^|[[:space:];|&(])([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)*rm([[:space:]]|$)'; then
  ask "rm command detected — confirm before deletion."
  exit 0
fi

# 2. git reset --hard / git checkout -- . / git restore destructive forms
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|checkout[[:space:]]+(--|\.)|restore[[:space:]]+--staged[[:space:]]+--worktree|clean[[:space:]]+(-fdx|-fd|-f))'; then
  ask "Destructive git command detected. Confirm you want to discard work."
  exit 0
fi

# 3. dd to a block device
if printf '%s' "$cmd" | grep -qE 'dd[[:space:]].*of=/dev/'; then
  deny "dd writing to a /dev node is disabled — too easy to wipe a disk."
  exit 0
fi

# 4. mkfs (filesystem format)
if printf '%s' "$cmd" | grep -qE 'mkfs(\.[a-z0-9]+)?[[:space:]]'; then
  deny "mkfs is disabled — formatting a filesystem is destructive."
  exit 0
fi

# 5. fork bomb
if printf '%s' "$cmd" | grep -qE ':\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:'; then
  deny "Fork-bomb pattern detected. Refusing to run."
  exit 0
fi

# 6. find ... -delete / find ... -exec rm
if printf '%s' "$cmd" | grep -qE 'find[[:space:]].*(-delete|-exec[[:space:]]+rm)'; then
  ask "find -delete / -exec rm detected. Confirm scope and targets."
  exit 0
fi

# 7. chmod 777 / chmod -R 777
if printf '%s' "$cmd" | grep -qE 'chmod[[:space:]]+(-R[[:space:]]+)?777'; then
  ask "chmod 777 is rarely correct. Confirm you really want world-writable."
  exit 0
fi

# 8. shutdown / reboot / halt / poweroff
if printf '%s' "$cmd" | grep -qE '(^|[[:space:];|&(])(shutdown|reboot|halt|poweroff)([[:space:]]|$)'; then
  deny "System power commands are disabled in Claude sessions."
  exit 0
fi

# 9. piping to bash (curl ... | bash) — last-line defense
if printf '%s' "$cmd" | grep -qE '\|[[:space:]]*(bash|sh|zsh|fish)(\s|$)'; then
  ask "Piping a download into a shell is risky. Confirm the source is trusted."
  exit 0
fi

exit 0
