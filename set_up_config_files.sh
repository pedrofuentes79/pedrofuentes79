#!/bin/bash

# Script to set up config files by creating hardlinks to their target locations
# Tuple format: "source:destination[:type]"
# type can be: file (default), recursive (for directories with cp -al)

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "Setting up config files..."
echo "Project directory: $PROJECT_DIR"
echo ""

# Array of tuples: "source:destination[:type]"
# - file: regular hardlink (default)
# - recursive: recursive hardlink for directories using cp -al
CONFIG_MAPPINGS=(
    "kitty.conf:$HOME_DIR/.config/kitty"
    "bindings.conf:$HOME_DIR/.config/hypr"
    "input.conf:$HOME_DIR/.config/hypr"
    "tiling-v2.conf:$HOME_DIR/.local/share/omarchy/default/hypr/bindings"
    "cursor-settings:$HOME_DIR/.config/Cursor/User:recursive"
    ".bashrc:$HOME_DIR"
    "ralt-super.xkb:$HOME_DIR/.config/xkb"
)

# Function to create hardlink for a file
create_hardlink() {
    local source=$1
    local dest_path=$2
    local link_type=${3:-file}
    local source_name=$(basename "$source")
    local target="$dest_path"
    
    # Determine target path: if destination basename matches source, use as-is; otherwise append source name
    if [ "$(basename "$dest_path")" != "$source_name" ]; then
        target="$dest_path/$source_name"
    fi
    
    # Create destination directory if needed
    local dest_dir=$(dirname "$target")
    if [ ! -d "$dest_dir" ]; then
        echo "Creating directory: $dest_dir"
        mkdir -p "$dest_dir"
    fi
    
    # Remove existing file/symlink if it exists
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Removing existing $(basename $target)"
        rm -rf "$target"
    fi
    
    # Create link based on type
    if [ "$link_type" = "recursive" ]; then
        # Use cp -al for recursive hardlinking of directories
        cp -al "$source" "$target"
        echo "✓ Created recursive hardlinks: $(basename $source) → $target"
    else
        # Regular hardlink for files
        ln "$source" "$target"
        echo "✓ Created hardlink: $source_name → $target"
    fi
}

# Function to process config mappings
process_config_mappings() {
    local mappings=("$@")
    
    for mapping in "${mappings[@]}"; do
        # Parse tuple: source:destination[:type]
        IFS=':' read -r source_path dest_path link_type <<< "$mapping"
        link_type="${link_type:-file}"
        
        source_file="$PROJECT_DIR/$source_path"
        
        if [ ! -e "$source_file" ]; then
            echo "⚠️  Warning: $source_path not found in $PROJECT_DIR"
            continue
        fi
        
        create_hardlink "$source_file" "$dest_path" "$link_type"
    done
}

# Process user-level config mappings
echo "Setting up user-level config files..."
process_config_mappings "${CONFIG_MAPPINGS[@]}"

echo "✓ Config files setup complete!"
