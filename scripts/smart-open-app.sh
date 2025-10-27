#!/bin/bash

# Smart Open - Generalized script for any application
# Focuses existing window or launches new app if none exists
# Usage: smart-open.sh <window_class> <window_title_pattern> <url>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <window_identifier> <launch_command>"
    echo "Example: $0 'WhatsApp' 'chromium --app=https://web.whatsapp.com/'"
    echo "Example: $0 'Spotify' 'spotify'"
    echo "Example: $0 'Discord' 'discord'"
    exit 1
fi

WINDOW_IDENTIFIER="$1"
LAUNCH_COMMAND="$2"

# Check if a window with the specified class or title exists
# Search by class first, then by title if not found
window_address=$(hyprctl clients -j | jq -r --arg identifier "$WINDOW_IDENTIFIER" '.[] | select(.class == $identifier or (.title | contains($identifier))) | .address' | head -n 1)

if [ -n "$window_address" ]; then
    # Window exists, focus it
    echo "Window found (identifier: $WINDOW_IDENTIFIER), focusing..."
    hyprctl dispatch focuswindow address:$window_address
else
    # No window found, launch new one
    echo "No window found (identifier: $WINDOW_IDENTIFIER), launching..."
    eval "$LAUNCH_COMMAND"
fi
