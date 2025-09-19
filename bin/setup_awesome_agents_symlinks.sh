#!/bin/bash

# Setup symlinks for Claude Code agents
# This script creates symlinks from the categories folder to ~/.claude/agents
# with flattened structure and category prefixes

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CATEGORIES_DIR="$PROJECT_ROOT/agents/awesome-claude-code-subagents/categories"
DESTINATION_DIR="$HOME/.claude/agents"

# Create destination directory if it doesn't exist
mkdir -p "$DESTINATION_DIR"

echo -e "${GREEN}Setting up agent symlinks...${NC}"
echo -e "Source: $CATEGORIES_DIR"
echo -e "Destination: $DESTINATION_DIR"
echo

# Arrays to track results
declare -a created_links=()
declare -a skipped_files=()

# Function to check if file should be skipped
should_skip_file() {
    local file="$1"
    local basename=$(basename "$file")

    # Skip README, LICENSE, CONTRIBUTING files (case insensitive)
    if [[ "$basename" =~ ^(readme|license|contributing).*$ ]] || \
       [[ "$basename" =~ ^(README|LICENSE|CONTRIBUTING).*$ ]]; then
        return 0
    fi

    # Skip hidden files and directories
    if [[ "$basename" == .* ]]; then
        return 0
    fi

    # Skip examples directories and files
    if [[ "$file" == *"/examples/"* ]] || [[ "$basename" == "examples"* ]]; then
        return 0
    fi

    return 1
}

# Check if categories directory exists
if [ ! -d "$CATEGORIES_DIR" ]; then
    echo -e "${RED}ERROR:${NC} Directory $CATEGORIES_DIR does not exist. Please run install.sh first."
    exit 1
fi

# Find all .md files in categories directory
while IFS= read -r -d '' file; do
    # Get relative path from categories directory
    rel_path="${file#$CATEGORIES_DIR/}"

    # Skip files we don't want
    if should_skip_file "$file"; then
        continue
    fi

    # Extract category folder name and remove numeric prefix
    category_folder=$(dirname "$rel_path")
    category_name="${category_folder#*-}"  # Remove everything up to and including first dash
    filename=$(basename "$rel_path")

    # Create flattened filename with category prefix
    if [[ "$category_name" != "." ]]; then
        flattened_filename="${category_name}-${filename}"
    else
        flattened_filename="$filename"
    fi

    # Create destination path (flattened)
    dest_file="$DESTINATION_DIR/$flattened_filename"

    # Check if symlink already exists
    if [[ -L "$dest_file" ]]; then
        skipped_files+=("$flattened_filename (symlink exists)")
        continue
    elif [[ -f "$dest_file" ]]; then
        skipped_files+=("$flattened_filename (file exists)")
        continue
    fi

    # Create symlink
    ln -s "$file" "$dest_file"
    created_links+=("$flattened_filename")

done < <(find "$CATEGORIES_DIR" -name "*.md" -type f -print0)

# Print results
echo -e "${GREEN}✓ Successfully created ${#created_links[@]} symlinks:${NC}"
for link in "${created_links[@]}"; do
    echo -e "  ${GREEN}→${NC} $link"
done

if [[ ${#skipped_files[@]} -gt 0 ]]; then
    echo
    echo -e "${YELLOW}⚠ Skipped ${#skipped_files[@]} files:${NC}"
    for file in "${skipped_files[@]}"; do
        echo -e "  ${YELLOW}→${NC} $file"
    done
fi

echo
echo -e "${GREEN}✓ Setup complete! Your agents are now symlinked to ~/.claude/agents${NC}"
echo -e "${GREEN}  Run 'git pull' in this directory to update your agents.${NC}"