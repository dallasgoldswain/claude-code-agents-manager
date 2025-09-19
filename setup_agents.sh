#!/bin/bash

# Script to create symlinks for agent files from dallasLabs folder to ~/.claude/agents folder
# Skips existing symlinks and lists files that were not symlinked

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Source directory
SOURCE_DIR="dallasLabs"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR:${NC} Directory $SOURCE_DIR does not exist."
    exit 1
fi

# Create ~/.claude/agents directory if it doesn't exist
mkdir -p ~/.claude/agents

# Array to store skipped files
skipped_files=()

echo "Setting up Dallas Labs agent symlinks to ~/.claude/agents..."
echo

# Get current directory
current_dir=$(pwd)

# Change to source directory
cd "$SOURCE_DIR"

# Loop through all files in dallasLabs directory
for file in *; do
    # Skip if it's a directory
    if [ -d "$file" ]; then
        continue
    fi

    # Skip hidden files (starting with .)
    if [[ "$file" == .* ]]; then
        continue
    fi

    # Skip README, LICENSE, CONTRIBUTING files (case insensitive)
    if [[ "$file" =~ ^(readme|license|contributing).*$ ]] || [[ "$file" =~ ^(README|LICENSE|CONTRIBUTING).*$ ]]; then
        continue
    fi

    # Skip examples directory files (if any examples files exist)
    if [[ "$file" =~ ^examples.*$ ]] || [[ "$file" =~ ^EXAMPLES.*$ ]]; then
        continue
    fi

    # Skip setup scripts
    if [[ "$file" == "setup_"*".sh" ]]; then
        continue
    fi

    # Target symlink path with dallas prefix
    target_path="$HOME/.claude/agents/dallas-$file"

    # Check if symlink or file already exists
    if [ -L "$target_path" ] || [ -e "$target_path" ]; then
        skipped_files+=("dallas-$file")
        echo -e "${YELLOW}SKIPPED:${NC} dallas-$file (already exists)"
    else
        # Create symlink
        ln -s "$current_dir/$SOURCE_DIR/$file" "$target_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}LINKED:${NC}  dallas-$file -> ~/.claude/agents/dallas-$file"
        else
            echo -e "${RED}ERROR:${NC}   Failed to create symlink for dallas-$file"
            skipped_files+=("dallas-$file")
        fi
    fi
done

# Return to original directory
cd "$current_dir"

echo
echo "Summary:"
echo "--------"

# Count successful links
total_files=$(find "$SOURCE_DIR" -maxdepth 1 -type f \
    ! -name ".*" \
    ! -iname "readme*" \
    ! -iname "license*" \
    ! -iname "contributing*" \
    ! -iname "examples*" \
    ! -name "setup_*.sh" | wc -l)

successful_links=$((total_files - ${#skipped_files[@]}))

echo "Total eligible files: $total_files"
echo "Successfully linked: $successful_links"
echo "Skipped files: ${#skipped_files[@]}"

if [ ${#skipped_files[@]} -gt 0 ]; then
    echo
    echo "Files that were not symlinked:"
    for file in "${skipped_files[@]}"; do
        echo "  - $file"
    done
fi

echo
echo -e "${GREEN}Setup complete!${NC}"
echo "Your Dallas Labs agent files are now symlinked to ~/.claude/agents/"