#!/usr/bin/env bash
# ~/.claude/hooks/lib.sh — shared helpers sourced by all Claude Code user-level hooks.
#
# Provides:
#   read_input          — parse the JSON stdin Claude Code sends to hooks
#   get_cmd / get_path  — extract common tool_input fields safely
#   get_branch          — current git branch (or empty string)
#   in_git_repo         — boolean
#   log_decision        — append-only line to ~/.claude/logs/policy.log
#   deny                — emit PreToolUse deny JSON on stdout
#   ask                 — emit PreToolUse ask JSON on stdout
#   warn_post           — emit PostToolUse systemMessage warning on stdout
#
# Conventions:
#   - All scripts return exit code 0 by default (no decision = no block)
#   - To BLOCK, print a JSON decision via deny() and exit 0
#   - To ALLOW, do nothing and exit 0
#   - exit 2 also blocks but without the structured JSON (use deny() instead)

# Resolve our own directory so this works regardless of how a hook is invoked
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export LIB_DIR

LOG="${HOME}/.claude/logs/policy.log"
mkdir -p "$(dirname "$LOG")"
touch "$LOG"
export LOG

# --- input parsing ---------------------------------------------------------

read_input() {
  # Read entire stdin into INPUT_JSON; tolerate empty stdin (some events pass none)
  INPUT_JSON="$(cat 2>/dev/null || true)"
  export INPUT_JSON
}

get_field() {
  # get_field <jq-expr>
  printf '%s' "$INPUT_JSON" | jq -r "$1 // empty" 2>/dev/null
}

get_cmd()    { get_field '.tool_input.command // empty'; }
get_path()   { get_field '.tool_input.file_path // empty'; }
get_url()    { get_field '.tool_input.url // empty'; }
get_tool()   { get_field '.tool_name // empty'; }
get_event()  { get_field '.hook_event_name // empty'; }
get_cwd()    { get_field '.cwd // empty'; }

# --- git helpers -----------------------------------------------------------

in_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

get_branch() {
  if in_git_repo; then
    git rev-parse --abbrev-ref HEAD 2>/dev/null
  else
    printf ''
  fi
}

# --- logging ---------------------------------------------------------------

log_decision() {
  # log_decision <tool> <decision> <reason>
  local tool="${1:-?}" decision="${2:-?}" reason="${3:-}"
  printf '%s | %-12s | %-5s | %s\n' \
    "$(date -u +%FT%TZ)" "$tool" "$decision" "$reason" >> "$LOG" 2>/dev/null || true
}

# --- PreToolUse decision emitters -----------------------------------------

deny() {
  # deny <reason>
  local reason="${1:-Blocked by user-level policy}"
  log_decision "${CLAUDE_TOOL_NAME:-$(get_tool)}" "deny" "$reason"
  jq -n --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
}

ask() {
  # ask <reason>
  local reason="${1:-Confirm before proceeding}"
  log_decision "${CLAUDE_TOOL_NAME:-$(get_tool)}" "ask" "$reason"
  jq -n --arg r "$reason" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
}

# --- PostToolUse / SessionStart emitters ----------------------------------

warn_post() {
  # warn_post <message>
  local msg="$1"
  log_decision "${CLAUDE_TOOL_NAME:-$(get_tool)}" "warn" "$msg"
  jq -n --arg m "$msg" --arg c "$msg" \
    '{systemMessage:$m,additionalContext:$c}'
}

# --- convenience pattern matchers -----------------------------------------

# contains_commit: returns 0 if the command line contains a `git commit` invocation
# (respects shell operators and the leading-assignment / wrapper stripping that
# Claude Code itself applies). Conservative — false positives are fine, they just
# trigger an extra check.
contains_git_commit() {
  printf '%s' "$1" | grep -qE '(^|[[:space:];|&(])([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)*git[[:space:]]+commit([[:space:]]|$)'
}

contains_git_push() {
  printf '%s' "$1" | grep -qE '(^|[[:space:];|&(])([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)*git[[:space:]]+push([[:space:]]|$)'
}

contains_force_push() {
  printf '%s' "$1" | grep -qE '(^|[[:space:]])git[[:space:]]+push[[:space:]].*(--force|-f([[:space:]]|$)|--force-with-lease)'
}

contains_plus_refspec() {
  # `git push origin +main` — the `+` refspec forces overwrite
  printf '%s' "$1" | grep -qE 'git[[:space:]]+push[[:space:]].*[[:space:]]\+[A-Za-z0-9_/.-]+([[:space:]]|$)'
}
