#!/usr/bin/env bash
# claude-dotfiles/install.sh — idempotent symlink installer.
#
# Symlinks the tracked files from this repo into ~/.claude/ so Claude Code
# picks them up. Re-runnable. Any pre-existing conflicting file is moved to
# ~/.claude/backups/<name>.<timestamp> first.
#
# Usage:
#   ./install.sh
#   REPO_DIR=/path/to/repo ./install.sh   # explicit override
#
# Works whether invoked as ./install.sh, bash install.sh, or piped from curl.

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

header "claude-dotfiles installer"

# Allow REPO_DIR override; default to the script's location
REPO_DIR="${REPO_DIR:-$SCRIPT_DIR}"
TARGET="$HOME/.claude"
BACKUPS="$TARGET/backups"

require_cmds claude git jq

# Sanity: are we actually inside a claude-dotfiles repo?
if [ ! -f "$REPO_DIR/settings.json" ] || [ ! -d "$REPO_DIR/hooks" ]; then
  err "✗ $REPO_DIR doesn't look like a claude-dotfiles checkout"
  err "  (missing settings.json or hooks/ directory)"
  exit 1
fi

# Make sure target dir exists
mkdir -p "$TARGET" "$BACKUPS"

info "Repo:    $REPO_DIR"
info "Target:  $TARGET"
info "Backups: $BACKUPS"
echo

# ── File mapping ────────────────────────────────────────────────────────
# Format: <repo-relative-path>|<~/.claude-relative-path>|<label>
# The label is what gets printed; the others are joined by '|'.
TRACKED=(
  "settings.json|settings.json|settings.json"
  "statusline.sh|statusline.sh|statusline.sh"
  "CLAUDE.md|CLAUDE.md|CLAUDE.md"
  "hooks/lib.sh|hooks/lib.sh|hooks/lib.sh"
  "hooks/block-main-commit.sh|hooks/block-main-commit.sh|hooks/block-main-commit.sh"
  "hooks/block-force-push.sh|hooks/block-force-push.sh|hooks/block-force-push.sh"
  "hooks/block-raw-network.sh|hooks/block-raw-network.sh|hooks/block-raw-network.sh"
  "hooks/protect-ci-workflows.sh|hooks/protect-ci-workflows.sh|hooks/protect-ci-workflows.sh"
  "hooks/block-destructive.sh|hooks/block-destructive.sh|hooks/block-destructive.sh"
  "hooks/session-guard.sh|hooks/session-guard.sh|hooks/session-guard.sh"
  "hooks/audit-writes.sh|hooks/audit-writes.sh|hooks/audit-writes.sh"
  "hooks/lint-ai-tells.sh|hooks/lint-ai-tells.sh|hooks/lint-ai-tells.sh"
)

header "Linking files"
for entry in "${TRACKED[@]}"; do
  IFS='|' read -r repo_path target_path label <<<"$entry"
  link_file "$REPO_DIR/$repo_path" "$TARGET/$target_path" "$label"
done

# ── Directory mappings (skills, agents, commands, rules) ────────────────
# These are directories in the repo, not files. We symlink each child file
# (and for skills, each subdirectory) into the corresponding ~/.claude/
# subdirectory. This preserves the layered structure (e.g. rules/common/)
# instead of flattening.
header "Linking skills / agents / rules"

link_dir() {
  # link_dir <repo-subdir> <target-subdir> <label>
  # For each file under <repo-subdir>, create a symlink in <target-subdir>.
  # Recurses one level so layered layouts (rules/common/) are preserved:
  # files in rules/common/ become ~/.claude/rules/common/<name>.md symlinks.
  # We never symlink a directory itself — that would create loops when the
  # install dir lives inside the same filesystem tree.
  #
  # Special case: for "skills", we symlink each top-level subdirectory as a
  # whole (so adding scripts/ or references/ to a skill is auto-available),
  # and skip the files inside those subdirs to avoid double-linking.
  local repo_sub="$1" target_sub="$2" label="$3"
  local repo_dir="$REPO_DIR/$repo_sub" target_dir="$TARGET/$target_sub"
  [ -d "$repo_dir" ] || { dim "  · $label (no $repo_sub/ in repo, skipping)"; return 0; }
  mkdir -p "$target_dir"

  if [ "$repo_sub" = "skills" ]; then
    # Link each skill as a whole directory.
    find "$repo_dir" -mindepth 1 -maxdepth 1 -type d -print0 |
    while IFS= read -r -d '' sub; do
      local n; n="$(basename "$sub")"
      link_file "$sub" "$target_dir/$n" "$label/$n"
    done
  else
    # Link every file (including files one level deep, e.g. rules/common/).
    find "$repo_dir" -type f -print0 |
    while IFS= read -r -d '' entry; do
      local rel name
      rel="${entry#$repo_dir/}"
      name="$rel"
      link_file "$entry" "$target_dir/$name" "$label/$name"
    done
  fi
}

link_dir "skills"   "skills"   "skills"
link_dir "agents"   "agents"   "agents"
link_dir "rules"    "rules"    "rules"

# Make sure all hook scripts in the repo are executable.
# (Symlinks preserve the perms of the target, so this hits the real files.)
find "$REPO_DIR/hooks" -maxdepth 1 -name '*.sh' -type f -exec chmod +x {} + 2>/dev/null || true
chmod +x "$REPO_DIR/statusline.sh" 2>/dev/null || true

# ── Summary ─────────────────────────────────────────────────────────────
header "Next steps"
ok "✓ Done."
dim ""
dim "  Verify the install:"
dim "    ls -la $TARGET/settings.json    # should be a symlink"
dim "    ls      $TARGET/skills/         # should list commit-message, tdd-workflow"
dim "    ls      $TARGET/agents/         # should list code-reviewer, security-reviewer, planner"
dim "    claude doctor                  # should report no errors"
dim "    cat $TARGET/logs/policy.log    # see policy decisions"
dim ""
dim "  Re-run anytime after \`git pull\` — safe, idempotent."
dim ""
dim "  Add a new hook:"
dim "    1. Drop the script in $REPO_DIR/hooks/"
dim "    2. Add an entry in settings.json under hooks.PreToolUse"
dim "    3. Test:  echo '<json>' | $REPO_DIR/hooks/your-hook.sh"
dim "    4. Commit, push, re-run ./install.sh"
dim ""
dim "  Add a new skill / agent / command / rule:"
dim "    1. Drop the file (or directory for skills) in the matching repo subdir."
dim "    2. Commit, push, re-run ./install.sh to symlink into ~/.claude/."
dim ""
