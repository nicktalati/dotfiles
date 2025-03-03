#!/usr/bin/env bash

BATTERY=$(cat /sys/class/power_supply/BAT0/capacity)
STATUS=$(cat /sys/class/power_supply/BAT0/status)

if [ "$BATTERY" -eq 0 ]; then
    level="0"
elif [ "$BATTERY" -le 10 ]; then
    level="10"
elif [ "$BATTERY" -le 20 ]; then
    level="20"
elif [ "$BATTERY" -le 30 ]; then
    level="30"
elif [ "$BATTERY" -le 40 ]; then
    level="40"
elif [ "$BATTERY" -le 50 ]; then
    level="50"
elif [ "$BATTERY" -le 60 ]; then
    level="60"
elif [ "$BATTERY" -le 70 ]; then
    level="70"
elif [ "$BATTERY" -le 80 ]; then
    level="80"
elif [ "$BATTERY" -le 90 ]; then
    level="90"
else
    level="100"
fi

if [ "$STATUS" = "Charging" ]; then
    if [ "$level" = "100" ]; then
        ICON="/usr/share/icons/Papirus-Dark/symbolic/status/battery-level-100-charged-symbolic.svg"
    else
        ICON="/usr/share/icons/Papirus-Dark/symbolic/status/battery-level-${level}-charging-symbolic.svg"
        if [ ! -f "$ICON" ]; then
            ICON="/usr/share/icons/Papirus-Dark/symbolic/status/battery-level-${level}-symbolic.svg"
        fi
    fi
else
    ICON="/usr/share/icons/Papirus-Dark/symbolic/status/battery-level-${level}-symbolic.svg"
fi

# Send the notification with the chosen icon.
notify-send -r 999 -u normal -t 1000 -i "$ICON" "${BATTERY}%"
