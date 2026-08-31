#!/usr/bin/env bash
# claude-dotfiles/bootstrap.sh — clone-or-update, then run install.sh.
#
# Designed for the one-liner:
#   curl -fsSL https://raw.githubusercontent.com/r3dpepper/claude-dotfiles/main/bootstrap.sh | bash
#
# What it does:
#   1. Verifies git is installed
#   2. If REPO_DIR already exists and is a git checkout pointing at REPO_URL → pulls
#   3. If REPO_DIR doesn't exist → clones
#   4. If REPO_DIR exists but is NOT a git checkout → refuses (safety)
#   5. Runs ./install.sh from inside the repo
#
# Override defaults via env vars:
#   REPO_URL=https://github.com/you/your-fork.git
#   REPO_DIR=$HOME/somewhere/else
#   BRANCH=main

set -euo pipefail

# Source shared helpers from the same dir as this script (works for both
# `bash bootstrap.sh` and `curl | bash`, since `curl | bash` writes to a
# temp file and BASH_SOURCE points at it).
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]:-}" != "bash" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/lib/common.sh" ]; then
  # curl|bash case: download lib/common.sh to a temp dir
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  # shellcheck disable=SC1091
  curl -fsSL "${REPO_URL:-https://github.com/r3dpepper/claude-dotfiles.git}/raw/main/lib/common.sh" \
    -o "$TMP_DIR/common.sh" 2>/dev/null || {
      err "✗ Could not download lib/common.sh from REPO_URL"
      err "  Set REPO_URL to your fork or run with: bash <(curl -fsSL https://...)"
      exit 1
    }
  SCRIPT_DIR="$TMP_DIR"
fi
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

# Defaults
REPO_URL="${REPO_URL:-https://github.com/r3dpepper/claude-dotfiles.git}"
REPO_DIR="${REPO_DIR:-$HOME/Learning/projects/claude-dotfiles}"
BRANCH="${BRANCH:-main}"

header "claude-dotfiles bootstrap"

require_cmds git curl

info "Repo URL: $REPO_URL"
info "Target:   $REPO_DIR"
info "Branch:   $BRANCH"
echo

# ── Decide what to do ──────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  # Existing git checkout
  current_remote="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || true)"
  case "$current_remote" in
    "$REPO_URL"|"${REPO_URL%.git}"|"${REPO_URL%.git}.git")
      info "↻ Existing checkout matches; pulling latest"
      git -C "$REPO_DIR" pull --ff-only
      ;;
    *)
      err "✗ $REPO_DIR is a git checkout, but 'origin' is:"
      err "    $current_remote"
      err "  This installer manages $REPO_URL."
      err "  Either back up $REPO_DIR and re-run, or repoint:"
      err "    git -C $REPO_DIR remote set-url origin $REPO_URL"
      exit 1
      ;;
  esac
elif [ -d "$REPO_DIR" ]; then
  # Exists but not a git checkout — refuse to clobber
  err "✗ $REPO_DIR exists but is not a git checkout"
  err "  Refusing to clobber. Move it aside first:"
  err "    mv $REPO_DIR $REPO_DIR.bak.\$(date +%Y%m%d-%H%M%S)"
  exit 1
else
  info "↻ Cloning $REPO_URL → $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

# ── Run the installer ──────────────────────────────────────────────────
echo
exec "$REPO_DIR/install.sh"
