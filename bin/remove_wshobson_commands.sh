#!/bin/bash

# Script to remove wshobson command symlinks from ~/.claude/commands/

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Removing wshobson command symlinks...${NC}"
echo

# Counter for removed files
removed_count=0
not_found_count=0

# Check if ~/.claude/commands directory exists
if [ ! -d "$HOME/.claude/commands" ]; then
    echo -e "${RED}Directory ~/.claude/commands does not exist.${NC}"
    exit 0
fi

# Function to remove symlinks from a directory
remove_symlinks_from_dir() {
    local dir_path="$1"
    local dir_name="$2"

    if [ ! -d "$dir_path" ]; then
        return 0
    fi

    echo "Removing symlinks from $dir_name/..."

    for link_path in "$dir_path"/*; do
        # Check if the glob pattern matched any files
        if [ ! -e "$link_path" ]; then
            continue
        fi

        # Get just the filename for display
        filename=$(basename "$link_path")

        if [ -L "$link_path" ]; then
            # It's a symlink, remove it
            rm "$link_path"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}REMOVED:${NC} $dir_name/$filename"
                ((removed_count++))
            else
                echo -e "${RED}ERROR:${NC}   Failed to remove $dir_name/$filename"
            fi
        elif [ -e "$link_path" ]; then
            # It exists but is not a symlink
            echo -e "${YELLOW}SKIPPED:${NC} $dir_name/$filename (not a symlink)"
            ((not_found_count++))
        fi
    done
}

# Remove symlinks from tools directory
remove_symlinks_from_dir "$HOME/.claude/commands/tools" "tools"

# Remove symlinks from workflows directory
remove_symlinks_from_dir "$HOME/.claude/commands/workflows" "workflows"

# Remove empty directories if they exist and are empty
if [ -d "$HOME/.claude/commands/tools" ] && [ -z "$(ls -A "$HOME/.claude/commands/tools")" ]; then
    rmdir "$HOME/.claude/commands/tools"
    echo -e "${GREEN}REMOVED:${NC} empty tools directory"
fi

if [ -d "$HOME/.claude/commands/workflows" ] && [ -z "$(ls -A "$HOME/.claude/commands/workflows")" ]; then
    rmdir "$HOME/.claude/commands/workflows"
    echo -e "${GREEN}REMOVED:${NC} empty workflows directory"
fi

# Remove commands directory if it's empty
if [ -d "$HOME/.claude/commands" ] && [ -z "$(ls -A "$HOME/.claude/commands")" ]; then
    rmdir "$HOME/.claude/commands"
    echo -e "${GREEN}REMOVED:${NC} empty commands directory"
fi

echo
echo "Summary:"
echo "--------"
echo "Removed symlinks: $removed_count"
echo "Skipped files: $not_found_count"

if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}wshobson command symlinks removal complete!${NC}"
else
    echo -e "${YELLOW}No wshobson command symlinks were found to remove.${NC}"
fi