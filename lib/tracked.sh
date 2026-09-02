# claude-dotfiles/lib/tracked.sh: shared install / uninstall mapping.
#
# Sourced (not executed). Provides:
#   TRACKED_FILES. Array of "<repo-path>|<target-path>|<label>".
#   TRACKED_DIRS. Array of "<repo-subdir>|<target-subdir>|<label>".
#
# Both install.sh and uninstall.sh read from this file so they cannot drift
# apart. Adding a new tracked item is a one-line edit here.
#
# File entry format: <repo-relative-path>|<~/.claude-relative-path>|<label>
# The label is what gets printed; the others are joined by '|'.
#
# Dir entry format: <repo-subdir>|<target-subdir>|<label>
# install.sh walks each dir and symlinks its children; uninstall.sh walks
# the same set and removes the resulting links.

# Files
TRACKED_FILES=(
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

# Directories
# Each entry is a directory in the repo whose children get linked into the
# matching ~/.claude/ subdir. Skills link as whole subdirs; agents and
# rules link each child file (one level deep, so rules/common/ is kept).
TRACKED_DIRS=(
  "skills|skills|skills"
  "agents|agents|agents"
  "rules|rules|rules"
)
