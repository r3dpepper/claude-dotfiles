#!/usr/bin/env bash
# SessionStart — verify git identity, branch state, and staged secrets.
# Non-blocking: emits warnings via additionalContext + systemMessage so both
# the user and Claude see them. Never denies the session.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input

# Build a list of warnings (one per finding)
warnings=""

if in_git_repo; then
  branch="$(get_branch)"

  # 1. On main/master with a clean checkout
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    warnings="${warnings}- You are on \`${branch}\`. Create a feature branch (\`git switch -c feat/...\`) before committing.\n"
  fi

  # 2. Git identity
  email="$(git config user.email 2>/dev/null || true)"
  name="$(git config user.name 2>/dev/null || true)"
  if [ -z "$email" ] || [ -z "$name" ]; then
    warnings="${warnings}- git identity is incomplete (name='${name}', email='${email}'). Set it before committing.\n"
  fi

  # 3. Staged secrets
  staged_diff="$(git diff --cached 2>/dev/null || true)"
  if [ -n "$staged_diff" ]; then
    if printf '%s' "$staged_diff" | grep -qE '(-----BEGIN [A-Z ]+ PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|xox[abprs]-[A-Za-z0-9-]{10,})'; then
      warnings="${warnings}- Possible secret detected in STAGED content. Run \`git diff --cached\` and unstage before committing.\n"
    fi
  fi

  # 4. Uncommitted changes (informational)
  uncommitted="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${uncommitted:-0}" -gt 0 ]; then
    warnings="${warnings}- Working tree has ${uncommitted} uncommitted change(s). Informational only.\n"
  fi
fi

# Emit a single SessionStart payload — empty if everything is clean
if [ -n "$warnings" ]; then
  msg="Session guard findings:\n${warnings}"
  jq -n --arg m "$msg" --arg c "$msg" \
    '{systemMessage:$m,additionalContext:$c}'
fi

exit 0
