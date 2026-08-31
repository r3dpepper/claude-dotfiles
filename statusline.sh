#!/bin/bash

# 1. Read JSON once from stdin
json=$(cat)
[ -z "$json" ] && exit 0

# 2. Extract ALL JSON variables in a single ultra-fast jq invocation
IFS=$'\t' read -r model ctx_percent ctx_size in_tokens out_tokens_json total_cost adds dels cwd < <(
    echo "$json" | jq -r '[
        (.model.display_name // "unknown"),
        (.context_window.used_percentage // 0),
        (.context_window.context_window_size // 200000),
        (.context_window.total_input_tokens // 0),
        (.context_window.total_output_tokens // 0),
        (.cost.total_cost_usd // 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0),
        (.workspace.current_dir // "")
    ] | @tsv'
)

# 3. Environment Fallbacks & Token Math
out_tokens_env=${CLAUDE_OUTPUT_TOKENS:-0}
out_tokens=$(( out_tokens_env > out_tokens_json ? out_tokens_env : out_tokens_json ))

in_k=$((in_tokens / 1000))
out_k=$((out_tokens / 1000))
total_tkns=$((in_k + out_k))
ctx_size_k=$((ctx_size / 1000))

cost_formatted=$(printf "%.2f" "$total_cost")

# 4. Fast Git Status Parsing (Avoids heavy while loops)
staged_files=0
modified_files=0
unstaged_files=0
git_branch=""

if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
    git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
    
    # Get all status lines into a variable once
    git_status=$(git -C "$cwd" status --porcelain 2>/dev/null)
    if [ -n "$git_status" ]; then
        staged_files=$(echo "$git_status" | grep -c -E '^[MADRC]')
        modified_files=$(echo "$git_status" | grep -c -E '^.[M]')
        unstaged_files=$(echo "$git_status" | grep -c -E '^\?\?')
    fi
fi

# 5. UI Formatting Codes
RESET=$'\e[0m'
BOLD=$'\e[1m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
BLUE=$'\e[34m'
MAGENTA=$'\e[35m'
CYAN=$'\e[36m'
BRIGHT_WHITE=$'\e[1;37m'

# Map threshold usage integers cleanly
percent_int=$(printf "%.0f" "$ctx_percent")
if [ "$percent_int" -gt 80 ]; then
    thinking="high"
    bar_color=$RED
elif [ "$percent_int" -gt 50 ]; then
    thinking="med"
    bar_color=$YELLOW
else
    thinking="low"
    bar_color=$GREEN
fi

# Safe Progress Bar generation (No external seq processes)
filled=$(( (20 * percent_int) / 100 ))
empty=$(( 20 - filled ))
bar=$(printf '█%.0s' $(seq 1 $filled 2>/dev/null); printf '░%.0s' $(seq 1 $empty 2>/dev/null))

# ==============================================================================
# Line 1 - Session Details
# ==============================================================================
echo -e "${BOLD}${YELLOW}Model:${RESET} ${BOLD}${MAGENTA}${model}${RESET} | ${BOLD}${CYAN}Thinking:${RESET} ${BOLD}${bar_color}${thinking}${RESET} | ${BOLD}${BLUE}Context:${RESET} [${bar_color}${bar}${RESET}] ${BOLD}${GREEN}${total_tkns}k/${ctx_size_k}k (${percent_int}%)${RESET}"

# ==============================================================================
# Line 2 - Directory, Git Branch, Cost, and Local Repository State Tracker
# ==============================================================================
if [ -n "$git_branch" ]; then
    echo -e "${BOLD}${BLUE}cwd:${RESET} ${BOLD}${CYAN}${cwd}${RESET} | ${BOLD}${MAGENTA}⎇  ${git_branch}${RESET} | ${BOLD}${GREEN}Stg:${RESET} ${BRIGHT_WHITE}${staged_files}${RESET} | ${BOLD}${YELLOW}Mod:${RESET} ${BRIGHT_WHITE}${modified_files}${RESET} | ${BOLD}${RED}New:${RESET} ${BRIGHT_WHITE}${unstaged_files}${RESET} | ${BOLD}${YELLOW}$:${RESET} ${GREEN}${cost_formatted}${RESET} (+${adds}/-${dels})"
else
    echo -e "${BOLD}${BLUE}cwd:${RESET} ${BOLD}${CYAN}${cwd}${RESET} | ${BOLD}${YELLOW}$:${RESET} ${GREEN}${cost_formatted}${RESET} (+${adds}/-${dels})"
fi

