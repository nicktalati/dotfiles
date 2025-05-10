#! /usr/bin/env bash

ICON_LOW="display-brightness-low-symbolic"
ICON_MEDIUM="display-brightness-medium-symbolic"
ICON_HIGH="display-brightness-high-symbolic"

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

    if [ "$PERCENT" -le 33 ]; then
        ICON="$ICON_LOW"
    elif [ "$PERCENT" -le 66 ]; then
        ICON="$ICON_MEDIUM"
    else
        ICON="$ICON_HIGH"
    fi

    notify-send -r 999 -u normal -t 500 -i "$ICON" "${PERCENT}%"
}

send_brightness_notification

sleep "$DELAY"

while true; do
    send_brightness_notification
    sleep "$INTERVAL"
done
