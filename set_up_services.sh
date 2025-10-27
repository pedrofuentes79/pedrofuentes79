#!/bin/bash

# Script to set up systemd services by creating hardlinks and enabling them
# This script creates hardlinks from the current directory to systemd user services

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

echo "Setting up systemd services..."
echo "Project directory: $PROJECT_DIR"
echo "Systemd user directory: $SYSTEMD_USER_DIR"

mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_FILES=(
    "campus_fetch.service"
    "campus_fetch.timer"
    "nightlight-auto.service"
    "nightlight-auto.timer"
    "update_gitlab_repos.service"
    "update_gitlab_repos.timer"
)

# Create hardlinks for each service file
for file in "${SERVICE_FILES[@]}"; do
    source_file="$PROJECT_DIR/$file"
    target_file="$SYSTEMD_USER_DIR/$file"
    
    if [ ! -f "$source_file" ]; then
        echo "⚠️  Warning: $file not found in $PROJECT_DIR"
        continue
    fi
    
    # Remove existing file if it exists (could be symlink or hardlink)
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        echo "Removing existing $file from $SYSTEMD_USER_DIR"
        rm "$target_file"
    fi
    
    # Create hardlink
    ln "$source_file" "$target_file"
    echo "✓ Created hardlink: $file"
done

# Reload systemd daemon to recognize new files
echo ""
echo "Reloading systemd user daemon..."
systemctl --user daemon-reload

# Enable and start the timer services (which will trigger the services)
echo ""
echo "Enabling and starting timer services..."
for file in "${SERVICE_FILES[@]}"; do
    if [[ "$file" == *.timer ]]; then
        service_name="${file%.timer}"
        echo "Enabling $file..."
        systemctl --user enable "$file"
        echo "Starting $file..."
        systemctl --user start "$file"
    fi
done

echo ""
echo "✓ Services setup complete!"
echo ""
echo "Summary of enabled timers:"
systemctl --user list-timers --all
