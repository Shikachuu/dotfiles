#!/usr/bin/env bash

# Cyberdream theme colors
PURPLE='\033[38;2;189;94;255m'
CYAN='\033[38;2;94;241;255m'
GREEN='\033[38;2;94;255;108m'
RED='\033[38;2;255;110;94m'
ORANGE='\033[38;2;255;189;94m'
YELLOW='\033[38;2;241;255;94m'
WHITE='\033[38;2;255;255;255m'
GREY='\033[38;2;123;132;150m'
RESET='\033[0m'

# Read JSON from stdin
JSON=$(cat)

# Parse JSON fields
CWD=$(echo "$JSON" | jq -r '.workspace.current_dir // empty')
MODEL=$(echo "$JSON" | jq -r '.model.display_name // "Unknown"')
LINES_ADDED=$(echo "$JSON" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$JSON" | jq -r '.cost.total_lines_removed // 0')
CONTEXT_PCT=$(echo "$JSON" | jq -r '.context_window.used_percentage // 0')

# Get git branch
if [ -n "$CWD" ]; then
    BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        BRANCH_DISPLAY="${PURPLE}(${BRANCH})${RESET}"
    else
        BRANCH_DISPLAY="${GREY}(-)${RESET}"
    fi
else
    BRANCH_DISPLAY="${GREY}(-)${RESET}"
fi

# Determine context color
if (( $(echo "$CONTEXT_PCT > 70" | bc -l) )); then
    CONTEXT_COLOR="$ORANGE"
elif (( $(echo "$CONTEXT_PCT >= 50" | bc -l) )); then
    CONTEXT_COLOR="$YELLOW"
else
    CONTEXT_COLOR="$WHITE"
fi

# Format output
OUTPUT="${BRANCH_DISPLAY} ${CYAN}[${MODEL}]${RESET} ${GREEN}+${LINES_ADDED}${RESET}${RED}/-${LINES_REMOVED}${RESET} | Context: ${CONTEXT_COLOR}${CONTEXT_PCT}%${RESET}"

echo -e "$OUTPUT"
