#! /usr/bin/env bash
# This script aims to produce a notification that;
#    the battery charging has reached above 80%, or
#    the battery capacity has reached below 20%
#
# It uses the command and its' output seen below.
#
# inxi -Bx
# Battery:
#   ID-1: BAT0 charge: 20.5 Wh (55.0%) condition: 37.3/37.1 Wh (100.6%)
#     volts: 8.3 min: 7.8 model: ASUSTeK ASUS Battery status: charging

# Dependency check
# Check if notify-send is installed
if ! command -v notify-send &> /dev/null; then
    echo This script requires that notify-send is installed. Please install it
    echo sudo apt install libnotify-bin
    exit 1
fi

function status_f {
    lfv=$(inxi -Bx | grep -i "status: " | sed 's/^.*status: //' | sed 's/charging.*/charging/')
    echo "$lfv"
}

function capacity_f {
    lfv=$(inxi -Bx | grep -i "charge: " | sed 's/^.*charge: //' | sed 's/:.*//' | sed 's/.*Wh (//' | sed 's/\.[0-9]%).*//')
    echo "$lfv"
}

function battery_check {
    status=$(status_f)
    cap=$(capacity_f)
    capacity=$(($cap)) # Convert to integer

    # Check conditions and return appropriate messages
    if [ "$status" = "discharging" ] && [ $capacity -le 20 ]; then
        action="start charging"
    elif [ "$status" = "charging" ] && [ $capacity -ge 80 ]; then
        action="stop charging"
    fi

    if [ "$action" != "" ]; then
        notify-send "Battery Watch Dog" "$action"
        action=""
    fi
}

while true; do battery_check; sleep 60; done