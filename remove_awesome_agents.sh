#!/bin/bash

# Script to remove awesome-claude-code-subagents symlinks from ~/.claude/agents/
# Removes all category-prefixed agents (excludes dLabs- and wshobson- prefixes)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Removing awesome-claude-code-subagents symlinks...${NC}"
echo

# Counter for removed files
removed_count=0
not_found_count=0

# Check if ~/.claude/agents directory exists
if [ ! -d "$HOME/.claude/agents" ]; then
    echo -e "${RED}Directory ~/.claude/agents does not exist.${NC}"
    exit 0
fi

# Function to check if a file should be removed (category-prefixed agents)
should_remove() {
    local filename="$1"
    # Skip dLabs and wshobson prefixed files
    if [[ "$filename" == dLabs-* ]] || [[ "$filename" == wshobson-* ]]; then
        return 1
    fi
    # Include files that contain a hyphen (category-prefixed)
    if [[ "$filename" == *-* ]]; then
        return 0
    fi
    return 1
}

# Find and remove category-prefixed agent symlinks
found_any=false
for link_path in "$HOME/.claude/agents"/*; do
    # Check if the glob pattern matched any files
    if [ ! -e "$link_path" ]; then
        continue
    fi

    # Get just the filename for display
    filename=$(basename "$link_path")

    # Check if this should be removed (category-prefixed agent)
    if should_remove "$filename"; then
        found_any=true

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
    fi
done

if [ "$found_any" = false ]; then
    echo -e "${YELLOW}No awesome-claude-code-subagents symlinks found.${NC}"
fi

echo
echo "Summary:"
echo "--------"
echo "Removed symlinks: $removed_count"
echo "Skipped files: $not_found_count"

if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}awesome-claude-code-subagents symlinks removal complete!${NC}"
else
    echo -e "${YELLOW}No awesome-claude-code-subagents symlinks were found to remove.${NC}"
fi