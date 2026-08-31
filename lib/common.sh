#!/usr/bin/env bash
# claude-dotfiles/lib/common.sh — shared helpers for install.sh and bootstrap.sh.
#
# Sourced (not executed). Provides:
#   COLORS  — ANSI color codes (empty when not a TTY, for clean logs)
#   log()   — timestamped log line to stderr
#   info/warn/err/ok — colored prefixed lines
#   require_cmds — check dependencies, print install hints, exit 1 on missing
#   self_dir — directory containing the calling script (resolves symlinks)

# ── Colors (empty when not a TTY) ────────────────────────────────────────
if [ -t 1 ] && [ -t 2 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; CYAN=$'\033[36m'
else
  BOLD=""; DIM=""; RESET=""
  RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""
fi
export BOLD DIM RESET RED GREEN YELLOW BLUE CYAN

# ── Logging ──────────────────────────────────────────────────────────────
log()   { printf '%s[%s]%s %s\n' "$DIM" "$(date +%H:%M:%S)" "$RESET" "$*" >&2; }
info()  { printf '%s%s%s\n' "$BLUE" "$*" "$RESET" >&2; }
warn()  { printf '%s%s%s\n' "$YELLOW" "$*" "$RESET" >&2; }
err()   { printf '%s%s%s\n' "$RED" "$*" "$RESET" >&2; }
ok()    { printf '%s%s%s\n' "$GREEN" "$*" "$RESET" >&2; }
header(){ printf '\n%s%s%s\n' "$BOLD$CYAN" "$*" "$RESET" >&2; }
dim()   { printf '%s%s%s\n' "$DIM" "$*" "$RESET" >&2; }

# ── Dependency check ────────────────────────────────────────────────────
require_cmds() {
  # require_cmds <cmd1> [cmd2 ...]
  # Prints install hints and exits 1 if any are missing.
  local missing=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    err "✗ Required dependencies not installed: ${missing[*]}"
    dim "  claude → curl -fsSL https://claude.ai/install.sh | bash"
    dim "  git    → https://git-scm.com/downloads (or: brew install git)"
    dim "  jq     → https://jqlang.org/download/ (or: brew install jq)"
    exit 1
  fi
}

# ── Self-locating helpers ───────────────────────────────────────────────
# Resolve the directory of the calling script (works for `bash script.sh`,
# `./script.sh`, and `curl | bash`).
self_dir() {
  local src="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  # Resolve symlinks
  while [ -L "$src" ]; do
    local dir="$(cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd)"
    src="$(readlink "$src")"
    [[ "$src" != /* ]] && src="$dir/$src"
  done
  cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd
}

# ── Symlink with backup ─────────────────────────────────────────────────
# link_file <source> <target> <label>
# Creates a symlink at <target> pointing to <source>.
# - If <target> is already a symlink to <source>: no-op
# - If <target> is a real file or wrong symlink: move to <target>.<timestamp> in
#   the same parent dir, then symlink
link_file() {
  local source="$1" target="$2" label="${3:-$target}"
  local parent; parent="$(dirname "$target")"
  mkdir -p "$parent"

  if [ -L "$target" ]; then
    local current; current="$(readlink "$target")"
    if [ "$current" = "$source" ]; then
      dim "  ✓ $label (already linked)"
      return 0
    fi
    # Wrong symlink — back up the link itself then replace
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    mv "$target" "${target}.bak.${ts}"
    warn "  ↻ $label (replaced old symlink → ${target}.bak.${ts})"
  elif [ -e "$target" ]; then
    # Real file — back it up
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    mv "$target" "${target}.bak.${ts}"
    warn "  ↻ $label (backed up → ${target}.bak.${ts})"
  else
    info "  + $label"
  fi

  ln -s "$source" "$target"
}

# ── Pretty summary ──────────────────────────────────────────────────────
# Counts of created / replaced / no-op links for a final report.
export LINKS_CREATED=0
export LINKS_REPLACED=0
export LINKS_NOOP=0
