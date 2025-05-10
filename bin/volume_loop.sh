#! /usr/bin/env bash
# Define icon paths for Papirus-Dark icons
ICON_LOW="audio-volume-low-symbolic"
ICON_MEDIUM="audio-volume-medium-symbolic"
ICON_HIGH="audio-volume-high-symbolic"
ICON_MUTED="audio-volume-muted-symbolic"


DIRECTION="$1"
DELAY=0.3
INTERVAL=0.1

if [ "$DIRECTION" = "up" ]; then
    CHANGE="5%+"
elif [ "$DIRECTION" = "down" ]; then
    CHANGE="5%-"
elif [ "$DIRECTION" = "mute" ]; then
    amixer -q set Master 0%
    notify-send -r 999 -u normal -t 1000 -i "$ICON_MUTED" "0%"
    exit 0
else
    echo "Usage: $0 {up|down|mute}"
    exit 1
fi

# Change the volume and get the current percentage
amixer -q set Master "$CHANGE"
PERCENT=$(amixer get Master | grep -o "[0-9]*%" | head -n1)
# Remove the % for numeric comparisons
NUM_PERCENT=${PERCENT%\%}

# Choose the appropriate icon based on volume level
if [ "$NUM_PERCENT" -eq 0 ]; then
    ICON="$ICON_MUTED"
elif [ "$NUM_PERCENT" -le 33 ]; then
    ICON="$ICON_LOW"
elif [ "$NUM_PERCENT" -le 66 ]; then
    ICON="$ICON_MEDIUM"
else
    ICON="$ICON_HIGH"
fi

notify-send -r 999 -u normal -t 500 -i "$ICON" "${PERCENT}"

sleep "$DELAY"

while true; do
    amixer -q set Master "$CHANGE"
    PERCENT=$(amixer get Master | grep -o "[0-9]*%" | head -n1)
    NUM_PERCENT=${PERCENT%\%}
    
    if [ "$NUM_PERCENT" -eq 0 ]; then
        ICON="$ICON_MUTED"
    elif [ "$NUM_PERCENT" -le 33 ]; then
        ICON="$ICON_LOW"
    elif [ "$NUM_PERCENT" -le 66 ]; then
        ICON="$ICON_MEDIUM"
    else
        ICON="$ICON_HIGH"
    fi

    notify-send -r 999 -u normal -t 500 -i "$ICON" "${PERCENT}"
    sleep "$INTERVAL"
done
