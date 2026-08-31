#!/usr/bin/env bash
# PostToolUse:Edit|Write — scan written files for accidentally-leaked secrets.
# PostToolUse cannot block (tool already ran) but can warn loudly so the user
# notices and revokes the credential.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
path="$(get_path)"
tool="$(get_tool)"

case "$tool" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

[ -n "$path" ] || exit 0
[ -f "$path" ] || exit 0

# Don't scan huge files (avoid reading the world)
size="$(wc -c < "$path" 2>/dev/null | tr -d ' ')"
[ "${size:-0}" -le 1048576 ] || exit 0   # 1 MiB cap

# Skip binary files (very rough check)
if file --mime "$path" 2>/dev/null | grep -qE 'charset=binary'; then
  exit 0
fi

# Run the scan
matches="$(grep -nE \
  -e 'AKIA[0-9A-Z]{16}'                                  \
  -e 'ASIA[0-9A-Z]{16}'                                  \
  -e 'ghp_[A-Za-z0-9]{36}'                               \
  -e 'gho_[A-Za-z0-9]{36}'                               \
  -e 'ghs_[A-Za-z0-9]{36}'                               \
  -e 'ghr_[A-Za-z0-9]{36}'                               \
  -e 'sk-ant-[A-Za-z0-9_-]{20,}'                         \
  -e 'sk-[A-Za-z0-9]{20,}'                               \
  -e 'xox[abprs]-[A-Za-z0-9-]{10,}'                      \
  -e '-----BEGIN [A-Z ]+ PRIVATE KEY-----'               \
  -e '"password"[[:space:]]*[:=][[:space:]]*"[^"]{6,}"'  \
  -e 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
  "$path" 2>/dev/null | head -5 || true)"

if [ -n "$matches" ]; then
  msg="⚠️  Possible secret(s) detected in ${path}:

${matches}

If these are real credentials, rotate them immediately and remove the file from git history. The audit log records this event."
  warn_post "$msg"
fi

exit 0
