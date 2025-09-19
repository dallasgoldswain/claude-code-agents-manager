#!/bin/bash

# Script to create symlinks for Claude commands from wshobson-commands
# Creates symlinks in ~/.claude/commands maintaining folder structure
# Only processes files from tools/ and workflows/ directories
# Preserves directory structure in destination

set -e

DEST_DIR="$HOME/.claude/commands"
SOURCE_DIR="wshobson-commands"
SKIPPED_FILES=()

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "ERROR: Directory $SOURCE_DIR does not exist. Please run install.sh first."
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Setting up wshobson command symlinks in $DEST_DIR..."

# Function to create symlink if it doesn't exist
create_symlink() {
    local src="$1"
    local dest="$2"
    local relative_path="$3"
    
    if [ -L "$dest" ] || [ -e "$dest" ]; then
        SKIPPED_FILES+=("$relative_path")
        return 1
    else
        # Create parent directory if needed
        mkdir -p "$(dirname "$dest")"
        ln -s "$src" "$dest"
        echo "✓ Linked: $relative_path"
        return 0
    fi
}

# Process tools directory (maintain structure)
if [ -d "$SOURCE_DIR/tools" ]; then
    echo ""
    echo "Processing wshobson tools directory..."
    for file in "$SOURCE_DIR/tools"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Skip hidden files
            if [[ "$filename" == .* ]]; then
                continue
            fi
            
            src_path="$(pwd)/$file"
            dest_path="$DEST_DIR/tools/$filename"
            create_symlink "$src_path" "$dest_path" "tools/$filename"
        fi
    done
fi

# Process workflows directory (maintain structure)
if [ -d "$SOURCE_DIR/workflows" ]; then
    echo ""
    echo "Processing wshobson workflows directory..."
    for file in "$SOURCE_DIR/workflows"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Skip hidden files
            if [[ "$filename" == .* ]]; then
                continue
            fi
            
            src_path="$(pwd)/$file"
            dest_path="$DEST_DIR/workflows/$filename"
            create_symlink "$src_path" "$dest_path" "workflows/$filename"
        fi
    done
fi

# Process root directory files
echo ""
echo "Processing wshobson root directory files..."
for file in "$SOURCE_DIR"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        
        # Skip hidden files
        if [[ "$filename" == .* ]]; then
            continue
        fi
        
        # Skip README, LICENSE, CONTRIBUTING files (case insensitive)
        if [[ "$filename" =~ ^(readme|license|contributing).*$ ]] || [[ "$filename" =~ ^(README|LICENSE|CONTRIBUTING).*$ ]]; then
            continue
        fi
        
        # Skip setup scripts
        if [[ "$filename" == "setup_"*".sh" ]]; then
            continue
        fi
        
        src_path="$(pwd)/$file"
        dest_path="$DEST_DIR/wshobson-$filename"
        create_symlink "$src_path" "$dest_path" "$filename"
    fi
done

# Report skipped files
if [ ${#SKIPPED_FILES[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Skipped files (already exist):"
    for file in "${SKIPPED_FILES[@]}"; do
        echo "   - $file"
    done
fi

echo ""
echo "✅ Symlink setup complete!"
echo "Wshobson commands are now available in: $DEST_DIR"
