#!/bin/bash

# Smart Open - Generalized script
# Focuses existing window or launches new app if none exists
# Usage: smart-open.sh <window_class> <window_title_pattern> <url>

if [ $# -lt 3 ]; then
    echo "Usage: $0 <window_class> <window_title_pattern> <url>"
    echo "Example: $0 chromium WhatsApp https://web.whatsapp.com/"
    exit 1
fi

WINDOW_CLASS="$1"
TITLE_PATTERN="$2"
URL="$3"

# Recreate the variables from bindings.conf
browser="uwsm app -- chromium --new-window --ozone-platform=wayland"
webapp="$browser --app"
LAUNCH_COMMAND="$webapp=$URL"

# Check if a window with the specified class and title pattern exists
window_address=$(hyprctl clients -j | jq -r --arg class "$WINDOW_CLASS" --arg title "$TITLE_PATTERN" '.[] | select(.class == $class and (.title | contains($title))) | .address')

if [ -n "$window_address" ]; then
    # Window exists, focus it
    echo "Window found (class: $WINDOW_CLASS, title: $TITLE_PATTERN), focusing..."
    hyprctl dispatch focuswindow address:$window_address
else
    # No window found, launch new one
    echo "No window found (class: $WINDOW_CLASS, title: $TITLE_PATTERN), launching..."
    eval "$LAUNCH_COMMAND"
fi
