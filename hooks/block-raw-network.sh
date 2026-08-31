#!/usr/bin/env bash
# PreToolUse:Bash — block raw network tools; let WebFetch handle allowlisted domains.
# We deny curl/wget/nc/scp/ftp/tftp/raw-ssh/rsync-over-network. These are
# already covered by permissions.deny rules, but hooks catch any spelling
# variations (e.g. `curl -s`, `/usr/bin/curl`) that pattern rules might miss.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
cmd="$(get_cmd)"
tool="$(get_tool)"

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

# Match the first token of the command (skip env-var assignments and wrappers
# Claude Code already strips: timeout, time, nice, nohup, stdbuf, command, builtin)
# We do a second pass for additional common wrappers and absolute paths.
trimmed="$cmd"
trimmed="${trimmed##*$(printf '\t')}"  # last tab-delimited token after a chain isn't useful; we want the first

# Extract the first executable word, conservatively
first="$(printf '%s' "$cmd" | sed -E 's/^[[:space:]]*//; s/^([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)+//; s/^(timeout|time|nice|nohup|stdbuf)[[:space:]]+//; s/^(command|builtin)[[:space:]]+//; s/^[[:space:]]*([^[:space:]]+).*/\1/')"

case "$first" in
  curl|wget|nc|netcat|ftp|tftp|scp|ssh)
    deny "Raw network tool '$first' is disabled. Use the WebFetch tool with an allowlisted domain, or run this command yourself outside Claude."
    exit 0
    ;;
esac

# rsync over network: `rsync user@host:...` or `rsync host:...`
if [ "$first" = "rsync" ] && printf '%s' "$cmd" | grep -qE 'rsync[[:space:]]+[^[:space:]]+:[^[:space:]]'; then
  deny "rsync over network is disabled. Use git, scp via your own terminal, or the WebFetch tool."
  exit 0
fi

# Python -c / node -e style "download a URL" — broad but safe catch
if printf '%s' "$cmd" | grep -qE '(python|python3|node|deno|bun)[[:space:]]+(-c|-e)[[:space:]]+.*(urllib|requests|fetch|http\.get|got\(|axios)'; then
  deny "Network access from inline scripts is disabled. Use the WebFetch tool with an allowlisted domain."
  exit 0
fi

exit 0
