#!/usr/bin/env bash
# PreToolUse:Edit|Write|MultiEdit — protect CI workflow files from edits.
# Belt-and-suspenders: also covered by permissions.deny rules, but hooks catch
# any path the rule pattern missed (symlinks, unusual layouts, generated paths).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

read_input
path="$(get_path)"
tool="$(get_tool)"

[ -n "$path" ] || exit 0
case "$tool" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# Normalize: strip trailing slashes; lowercase
norm="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"
norm="${norm%/}"

# Match common CI workflow locations. We use extended globs because the leading
# dot in `.github` makes naive `*/.github` patterns not match (the `*` needs at
# least one character before the `/`). Both `/.github/workflows/...` and
# `./.github/workflows/...` (relative) and `/abs/path/.github/workflows/...` are
# covered.
shopt -s extglob nullglob 2>/dev/null || true
case "$norm" in
  */.github/workflows/*|.github/workflows/*)
    deny "Editing CI workflow files is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */.github/workflows.yml|*/.github/workflows.yaml|.github/workflows.yml|.github/workflows.yaml)
    deny "Editing CI workflow files is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */.gitlab-ci.yml|.gitlab-ci.yml)
    deny "Editing CI config is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */.circleci/config.yml|*/.circleci/config.yaml|.circleci/config.yml|.circleci/config.yaml|*/.circleci/*|*.circleci/config.yml)
    deny "Editing CI config is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */jenkinsfile|./*/jenkinsfile|jenkinsfile)
    deny "Editing CI config is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */bitbucket-pipelines.yml|*/bitbucket-pipelines.yaml|bitbucket-pipelines.yml|bitbucket-pipelines.yaml)
    deny "Editing CI config is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
  */.travis.yml|*/appveyor.yml|*/azure-pipelines.yml|.travis.yml|appveyor.yml|azure-pipelines.yml)
    deny "Editing CI config is disabled at the user level. Open a PR and review with a teammate."
    exit 0
    ;;
esac

exit 0
