#!/usr/bin/env bash
# claude-dotfiles/uninstall.sh: inverse of install.sh.
#
# Removes the symlinks install.sh created in ~/.claude/. Only touches
# symlinks that point into a path containing /claude-dotfiles/; never
# touches real files, never touches symlinks from other tools, and
# never deletes the repo itself.
#
# After removing a symlink, offers to restore the most recent
# ~/.claude/<name>.bak.<timestamp> backup (if one exists) created by
# install.sh's link_file helper.
#
# Usage:
#   ./uninstall.sh                 # interactive; prompts before removing
#   ./uninstall.sh --yes           # skip the confirm prompt (for scripts)
#   ./uninstall.sh --restore       # also restore the newest .bak.<ts>
#   ./uninstall.sh --no-restore    # remove but do not restore backups
#   ./uninstall.sh --yes --restore # both, non-interactive
#
# Re-runnable. On a clean state it prints "nothing to remove" and exits 0.

set -euo pipefail

# Source shared helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/tracked.sh
. "$SCRIPT_DIR/lib/tracked.sh"

# Argument parsing
ASSUME_YES=0
DO_RESTORE=""
for arg in "$@"; do
  case "$arg" in
    --yes|-y)       ASSUME_YES=1 ;;
    --restore)      DO_RESTORE="yes" ;;
    --no-restore)   DO_RESTORE="no" ;;
    -h|--help)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *)
      err "✗ Unknown argument: $arg"
      err "  Run with --help for usage."
      exit 2
      ;;
  esac
done

TARGET="$HOME/.claude"
REPO_MARKER="claude-dotfiles"  # symlink target path must contain this

header "claude-dotfiles uninstaller"
info "Target: $TARGET"
info "Repo marker: any symlink whose target path contains /$REPO_MARKER/"
echo

# Confirm gate
if [ "$ASSUME_YES" -eq 0 ]; then
  if [ -t 0 ]; then
    printf '%sRemove all claude-dotfiles symlinks from %s? [y/N]%s ' \
      "$YELLOW$BOLD" "$TARGET" "$RESET" >&2
    read -r answer
    case "$answer" in
      y|Y|yes|YES) ;;
      *) err "Aborted."; exit 1 ;;
    esac
  else
    err "✗ No TTY on stdin; pass --yes to run non-interactively."
    exit 1
  fi
fi

# Symlink classifier
# classify_target <path> <expected_repo_relative>
#   Sets the global variable CLASS to one of:
#     ours: symlink into this repo, safe to remove
#     other: symlink to somewhere else, leave alone
#     real: real file, leave alone
#     missing: doesn't exist, nothing to do
classify_target() {
  local path="$1" expected_repo_rel="$2"
  if [ -L "$path" ]; then
    local target; target="$(readlink "$path")"
    # Resolve relative targets against the symlink's parent dir.
    if [[ "$target" != /* ]]; then
      target="$(cd "$(dirname "$path")" && cd "$target" 2>/dev/null && pwd || true)"
    fi
    if [[ "$target" == *"/$REPO_MARKER/"* ]] || [[ "$target" == *"/$REPO_MARKER" ]]; then
      CLASS="ours"
    else
      CLASS="other"
    fi
  elif [ -e "$path" ]; then
    CLASS="real"
  else
    CLASS="missing"
  fi
}

# Counts and removed-list for the summary
REMOVED=0
SKIPPED_OTHER=0
SKIPPED_REAL=0
SKIPPED_MISSING=0

# Remove one tracked file target
remove_file_target() {
  # remove_file_target <target_path> <label>
  local target_path="$1" label="$2"
  local full="$TARGET/$target_path"
  classify_target "$full" "$target_path"
  case "$CLASS" in
    ours)
      rm "$full"
      ok "  - $label"
      REMOVED=$((REMOVED + 1))
      ;;
    other)
      local tgt; tgt="$(readlink "$full")"
      warn "  · $label (symlink -> $tgt, not ours, leaving)"
      SKIPPED_OTHER=$((SKIPPED_OTHER + 1))
      ;;
    real)
      warn "  · $label (real file, leaving)"
      SKIPPED_REAL=$((SKIPPED_REAL + 1))
      ;;
    missing)
      dim "  · $label (not present)"
      SKIPPED_MISSING=$((SKIPPED_MISSING + 1))
      ;;
  esac
}

# Collect the file-target paths inside a tracked dir so the main shell
# can iterate them. We can't call remove_file_target from inside a
# `find ... | while` pipeline, because the while runs in a subshell and
# its updates to the global counters die with it. So: collect paths
# into DIR_TARGETS, then iterate in the main shell.
DIR_TARGETS=()

collect_dir_targets() {
  # collect_dir_targets <target_subdir> <label>
  # Populates DIR_TARGETS with "<relpath>|<label>" entries.
  local target_sub="$1" label="$2"
  local target_dir="$TARGET/$target_sub"
  [ -d "$target_dir" ] || { dim "  · $label (no $target_sub/ in target, skipping)"; return 0; }

  if [ "$target_sub" = "skills" ]; then
    # Each top-level child of skills/ is a symlink to a subdir (e.g.
    # ~/.claude/skills/plan -> repo/skills/plan). Match the symlinks
    # themselves, not what they point to; -type l catches the link.
    while IFS= read -r -d '' sub; do
      DIR_TARGETS+=("$target_sub/$(basename "$sub")|$label/$(basename "$sub")")
    done < <(find "$target_dir" -mindepth 1 -maxdepth 1 -type l -print0 2>/dev/null)
  else
    # agents and rules: each child file at depth 1 (e.g. agents/*.md) and
    # depth 2 (e.g. rules/common/*.md) is a symlink to a file in the repo.
    # Use -maxdepth 2 to mirror what install.sh's `find -type f` reached.
    while IFS= read -r -d '' entry; do
      local rel="${entry#$target_dir/}"
      DIR_TARGETS+=("$target_sub/$rel|$label/$rel")
    done < <(find "$target_dir" -mindepth 1 -maxdepth 2 -type l -print0 2>/dev/null)
  fi
}

# Run the remove pass
header "Removing symlinks"
for entry in "${TRACKED_FILES[@]}"; do
  IFS='|' read -r _ target_path label <<<"$entry"
  remove_file_target "$target_path" "$label"
done

for entry in "${TRACKED_DIRS[@]}"; do
  IFS='|' read -r _ target_sub label <<<"$entry"
  collect_dir_targets "$target_sub" "$label"
done

if [ "${#DIR_TARGETS[@]}" -gt 0 ]; then
  for spec in "${DIR_TARGETS[@]}"; do
    IFS='|' read -r target_path label <<<"$spec"
    remove_file_target "$target_path" "$label"
  done
fi

# Backup restoration pass
# Look for .bak.<ts> siblings of removed targets. We check the same set
# the install created backups for: the 12 file targets, plus the
# children of skills/, agents/, rules/.
RESTORED=0
BACKUPS_LEFT=()

collect_backup_candidates() {
  # collect_backup_candidates <target_path>
  # Appends any <target_path>.bak.<ts> files to BACKUPS_LEFT.
  local target_path="$1"
  local full="$TARGET/$target_path"
  local parent; parent="$(dirname "$full")"
  local base; base="$(basename "$full")"
  # match the exact target plus ".bak." + timestamp
  for bak in "$parent/$base".bak.*; do
    [ -e "$bak" ] || continue
    BACKUPS_LEFT+=("$bak")
  done
}

for entry in "${TRACKED_FILES[@]}"; do
  IFS='|' read -r _ target_path _ <<<"$entry"
  collect_backup_candidates "$target_path"
done

for entry in "${TRACKED_DIRS[@]}"; do
  IFS='|' read -r _ target_sub _ <<<"$entry"
  collect_backup_candidates "$target_sub"
done

if [ "${#BACKUPS_LEFT[@]}" -gt 0 ]; then
  do_restore="$DO_RESTORE"
  if [ -z "$do_restore" ] && [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ]; then
    echo >&2
    printf '%sFound %d backup file(s) from previous installs. Restore the most recent? [y/N]%s ' \
      "$YELLOW$BOLD" "${#BACKUPS_LEFT[@]}" "$RESET" >&2
    read -r answer
    case "$answer" in
      y|Y|yes|YES) do_restore="yes" ;;
      *)           do_restore="no"  ;;
    esac
  fi

  if [ "$do_restore" = "yes" ]; then
    header "Restoring backups"
    # For each removed target, find the newest matching backup and move it
    # back. The timestamp portion of "<name>.bak.<ts>" sorts lexically
    # because the installer uses YYYYMMDD-HHMMSS. Sort all backups
    # newest-first, then restore the first one we see for each base.
    RESTORED_BASES=""
    # Use a tempfile because ${BACKUPS_LEFT[@]} can be large and contains
    # spaces/odd characters. printf handles quoting correctly.
    SORTED_BAKS="$(mktemp)"
    trap 'rm -f "$SORTED_BAKS"' EXIT
    for bak in "${BACKUPS_LEFT[@]}"; do
      printf '%s\n' "$bak"
    done | sort -r > "$SORTED_BAKS"
    while IFS= read -r bak; do
      [ -n "$bak" ] || continue
      local_base="${bak%.bak.*}"
      case " $RESTORED_BASES " in
        *" $local_base "*) continue ;;  # already restored this base
      esac
      if [ -e "$local_base" ]; then
        # Target still has something (e.g. a real file from another tool).
        # Don't clobber; leave the backup in place.
        warn "  · $local_base already exists, leaving backup at $bak"
        RESTORED_BASES="$RESTORED_BASES $local_base"
        continue
      fi
      mv "$bak" "$local_base"
      ok "  ↻ $local_base (restored from $bak)"
      RESTORED=$((RESTORED + 1))
      RESTORED_BASES="$RESTORED_BASES $local_base"
    done < "$SORTED_BAKS"
  else
    dim "  · Skipped backup restoration. Backups remain in place."
  fi
fi

# Summary
header "Summary"
ok "✓ Removed:    $REMOVED"
[ "$SKIPPED_OTHER" -gt 0 ]   && dim "  Skipped (other symlink): $SKIPPED_OTHER"
[ "$SKIPPED_REAL" -gt 0 ]    && dim "  Skipped (real file):     $SKIPPED_REAL"
[ "$SKIPPED_MISSING" -gt 0 ] && dim "  Already absent:          $SKIPPED_MISSING"
[ "$RESTORED" -gt 0 ]        && ok "✓ Restored:   $RESTORED"

if [ "${#BACKUPS_LEFT[@]}" -gt 0 ] && [ "${DO_RESTORE:-}" != "yes" ]; then
  echo >&2
  dim "Backups left in place (most recent first):"
  # Sort by timestamp descending, show top 10.
  printf '%s\n' "${BACKUPS_LEFT[@]}" | sort -r | head -10 | while read -r p; do
    dim "  $p"
  done
  if [ "${#BACKUPS_LEFT[@]}" -gt 10 ]; then
    dim "  ... and $(( ${#BACKUPS_LEFT[@]} - 10 )) more"
  fi
fi

echo >&2
dim "The repo at $SCRIPT_DIR was NOT touched."
dim "Run ./install.sh to re-install; remove the repo manually if you want it gone."
