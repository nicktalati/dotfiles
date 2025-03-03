#! /usr/bin/env bash

ICON_OFF="/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-off-symbolic.svg"
ICON_LOW="/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-low-symbolic.svg"
ICON_MEDIUM="/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-medium-symbolic.svg"
ICON_HIGH="/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-high-symbolic.svg"
DEFAULT_ICON="/usr/share/icons/Papirus-Dark/symbolic/status/display-brightness-symbolic.svg"

DIRECTION="$1"
DELAY=0.3
INTERVAL=0.1

if [ "$DIRECTION" = "up" ]; then
    CHANGE="+5%"
elif [ "$DIRECTION" = "down" ]; then
    CHANGE="5%-"
else
    echo "Usage: $0 {up|down}"
    exit 1
fi

send_brightness_notification() {
    brightnessctl -q s "$CHANGE"
    CURRENT=$(brightnessctl g)
    MAX=$(brightnessctl m)
    PERCENT=$((CURRENT * 100 / MAX))

    if [ "$PERCENT" -eq 0 ]; then
        ICON="$ICON_OFF"
    elif [ "$PERCENT" -le 33 ]; then
        ICON="$ICON_LOW"
    elif [ "$PERCENT" -le 66 ]; then
        ICON="$ICON_MEDIUM"
    elif [ "$PERCENT" -le 100 ]; then
        ICON="$ICON_HIGH"
    else
        ICON="$DEFAULT_ICON"
    fi

    notify-send -r 999 -u normal -t 500 -i "$ICON" "${PERCENT}%"
}

send_brightness_notification

sleep "$DELAY"

while true; do
    send_brightness_notification
    sleep "$INTERVAL"
done
