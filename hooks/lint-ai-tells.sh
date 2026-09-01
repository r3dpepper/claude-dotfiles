#!/usr/bin/env bash
# PreToolUse:Write|Edit|MultiEdit: lint written content for AI writing tells.
# Catches em-dash, en-dash, and a small set of high-confidence vocabulary
# tells that the rule and skill missed. Denies the write so Claude can
# rewrite the content in context.
#
# Code-safe exceptions:
#   - Unicode escape sequences like the literal em/en-dash in source
#     code (only the rendered character is banned; the escape form is
#     fine and preferred)
#   - Regex patterns that match the literal characters
#   - Test fixtures and data files where the banned strings are
#     legitimately part of the data
#   - Per-line override `// ai-tell-ok` (or `# ai-tell-ok` / `-- ai-tell-ok`)
#     on the line that needs the literal character. The marker also
#     exempts the next non-blank line, matching the conventional
#     `noqa` / `eslint-disable-next-line` pattern.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
path="$(get_path)"
tool="$(get_tool)"

# Only act on Write / Edit / MultiEdit
case "$tool" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

# No path -> nothing to scan
[ -n "$path" ] || exit 0

# The content lives in different fields depending on the tool:
#   Write:       tool_input.content
#   Edit:        tool_input.new_string
#   MultiEdit:   tool_input.edits[*].new_string  (JSON array)
content="$(printf '%s' "$INPUT_JSON" | jq -r '
  if .tool_input.content        then .tool_input.content
  elif .tool_input.new_string  then .tool_input.new_string
  elif .tool_input.edits        then (.tool_input.edits | map(.new_string) | join("\n"))
  else ""
  end' 2>/dev/null)"

[ -n "$content" ] || exit 0

# We do NOT scan for structural tells (rule-of-three, puffery, vague
# attribution) because those need a human eye. The hook only catches
# the unambiguous, mechanically-detectable tells.

# Punctuation: em-dash (U+2014) and en-dash (U+2013)
# Vocabulary: a short, high-confidence list of words LLMs overuse at
#   high rates. We scan word-bounded with case-insensitive match.
#   The rule/skill cover the long list; this hook is the safety net
#   for the most flagrant cases.
# ai-tell-ok
BANNED_WORDS='delve|delves|delved|delving|leverage|leverages|leveraged|leveraging|navigate|navigates|navigated|navigating|showcase|showcases|showcased|showcasing|unlock|unlocks|unlocked|unlocking|tapestry|tapestries|seamless|seamlessly|robust|comprehensive|crucial|pivotal|meticulous|meticulously|underscore|underscores|underscored|underscoring|enduring|ever-evolving|game-changer|game-changing|paradigm shift|holistic|cutting-edge|state-of-the-art|next-generation|revolutionary|groundbreaking|transformative|unprecedented'

# Walk the content line by line. The override marker exempts the
# current line and the next non-blank line. We use awk to track this
# and preserve original line numbers in the deny message.
#
# Output: each match is printed as a line of the form "N:TYPE:LABEL"
# where N is the original 1-indexed line number, TYPE is "punct" or
# "vocab", and LABEL is "em-dash (U+2014)" or the matched word.
matches=$(printf '%s' "$content" | awk -v words="$BANNED_WORDS" '
  BEGIN {
    skip_next = 0
    n = split(words, arr, "|")
    found = 0
  }
  {
    is_exempt = 0
    if (skip_next) {
      is_exempt = 1
      skip_next = 0
    } else if (tolower($0) ~ /[ \t]ai-tell-ok([ \t]|$)/) {
      is_exempt = 1
      skip_next = 1
    }
    if (is_exempt) next

    # Punctuation: em-dash, en-dash
    // ai-tell-ok
    if (match($0, /—/)) {
      print NR ":punct:em-dash (U+2014)"
      found = 1
    }
    // ai-tell-ok
    if (match($0, /–/)) {
      print NR ":punct:en-dash (U+2013)"
      found = 1
    }

    # Vocabulary: word-bounded, case-insensitive
    lc = tolower($0)
    for (i = 1; i <= n; i++) {
      w = arr[i]
      re = "[^A-Za-z0-9_]" w "[^A-Za-z0-9_]"
      if (lc ~ re) {
        print NR ":vocab:" w
        found = 1
      }
    }
  }
  END { exit (found ? 0 : 1) }
' 2>/dev/null) || true

[ -z "$matches" ] && exit 0

# Format the deny message with original line numbers and a one-line
# preview of the offending line.
preview_punc=""
preview_vocab=""
if printf '%s\n' "$matches" | grep -q ':punct:'; then
  preview_punc=$(printf '%s\n' "$matches" | grep ':punct:' | while IFS=: read -r n t label; do
    line=$(printf '%s\n' "$content" | sed -n "${n}p")
    printf "  line %d: %s\n  %s\n\n" "$n" "$label" "${line:0:200}"
  done)
fi
if printf '%s\n' "$matches" | grep -q ':vocab:'; then
  preview_vocab=$(printf '%s\n' "$matches" | grep ':vocab:' | while IFS=: read -r n t label; do
    line=$(printf '%s\n' "$content" | sed -n "${n}p")
    printf "  line %d: %s\n  %s\n\n" "$n" "$label" "${line:0:200}"
  done)
fi

msg="AI writing tells found in content for $path."
[ -n "$preview_punc" ] && msg="$msg

Punctuation (em-dash U+2014 or en-dash U+2013): these are the most visible AI tells.
$preview_punc"
[ -n "$preview_vocab" ] && msg="$msg

Vocabulary (overused AI words at statistically elevated rates):
$preview_vocab"
msg="$msg
Fix: rewrite the offending sentences in context. Do not character-swap. See the avoid-ai-tells skill for the procedure and the ai-tells rule for the full replacement table. Per-line override: add '// ai-tell-ok' (or comment-style equivalent) on the line that legitimately needs the literal character; the override also exempts the next non-blank line."

deny "$msg"
