#!/bin/bash

# Script to remove wshobson agent symlinks from ~/.claude/agents/

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Removing wshobson agent symlinks...${NC}"
echo

# Counter for removed files
removed_count=0
not_found_count=0

# Check if ~/.claude/agents directory exists
if [ ! -d "$HOME/.claude/agents" ]; then
    echo -e "${RED}Directory ~/.claude/agents does not exist.${NC}"
    exit 0
fi

# Remove wshobson agent symlinks
for link_path in "$HOME/.claude/agents"/wshobson-*; do
    # Check if the glob pattern matched any files
    if [ ! -e "$link_path" ]; then
        echo -e "${YELLOW}No wshobson agent symlinks found.${NC}"
        break
    fi

    # Get just the filename for display
    filename=$(basename "$link_path")

    if [ -L "$link_path" ]; then
        # It's a symlink, remove it
        rm "$link_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}REMOVED:${NC} $filename"
            ((removed_count++))
        else
            echo -e "${RED}ERROR:${NC}   Failed to remove $filename"
        fi
    elif [ -e "$link_path" ]; then
        # It exists but is not a symlink
        echo -e "${YELLOW}SKIPPED:${NC} $filename (not a symlink)"
        ((not_found_count++))
    fi
done

echo
echo "Summary:"
echo "--------"
echo "Removed symlinks: $removed_count"
echo "Skipped files: $not_found_count"

if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}wshobson agent symlinks removal complete!${NC}"
else
    echo -e "${YELLOW}No wshobson agent symlinks were found to remove.${NC}"
fi