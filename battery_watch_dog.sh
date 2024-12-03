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
# debug: set -euxo pipefail

# Dependency check
# Check if notify-send is installed
if ! command -v notify-send &> /dev/null; then
    echo This script requires that notify-send is installed. Please install it
    echo sudo apt install libnotify-bin
    exit 1
fi

echo "$0 is starting"

function battery_regexp_f {
    b_re=$(inxi -B|grep -o "ID-1: [a-zA-Z0-9_-]\+ ")
    echo "$b_re"
}

function status_f {
    b_re=$(battery_regexp_f)
    status=$(inxi -Bx|grep -A 1 "$b_re"|grep "status: "|sed 's/^.*status: //'|\grep -Eo 'full|charging|discharging')
    echo "$status"
}

function capacity_f {
    b_re=$(battery_regexp_f)
    percentage=$(inxi -Bx | grep -A 1 "$b_re"|grep -o "charge: [0-9.]\+ Wh .[0-9.]\+"|grep -o "[(][0-9]\+"|grep -o "[0-9]\+")
    echo "$percentage"
}

function battery_check {
    status=$(status_f)
    cap=$(capacity_f)
    capacity=$((cap)) # Convert to integer

    action=""
    # Check conditions and return appropriate messages
    if [ "$status" = "full" ]; then
        action=""
    elif [ "$status" = "discharging" ] && [ $capacity -le 10 ]; then
        action="force Hibernate within 1 minute !!"
        notify-send "Battery Watch Dog" "$action"
        sleep 60
        systemctl hibernate
        sleep 120
    elif [ "$status" = "discharging" ] && [ $capacity -le 20 ]; then
        action="start charging"
    elif [ "$status" = "full" ]; then
        action=""
    elif [ "$status" = "charging" ] && [ $capacity -ge 90 ]; then
        action=""
    elif [ "$status" = "charging" ] && [ $capacity -ge 80 ]; then
        action="stop charging"
    fi

    if [ "$action" != "" ]; then
        notify-send "Battery Watch Dog" "$action"
        action=""
    fi
}

while true; do battery_check; sleep 60; done
