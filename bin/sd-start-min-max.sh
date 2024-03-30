#!/bin/bash
# This script acts as a launcher for apps that observes the following rules:
# 1. If the app is not running, then start it up
# 2. If the app is running, don’t start a second instance, instead:
# 2a. If the app does not have focus, give it focus
# 2b. If the app has focus, minimize it
# Reference link: http://forum.xfce.org/viewtopic.php?id=6168&p=1 7
# there has to be at least one parameter, the name of the file to execute

if [ $# -lt 1 ]; then
    echo “Usage: $(basename $0) {executable_name parameters}”
    exit 1
fi

BNAME=$(basename $1)
echo $BNAME

# test to see if program is already running
if [ "$(wmctrl -lx | tr -s ' ' | cut -d' ' -f1-3 | grep -i $BNAME)" ]; then
    # means it must already be running
    ACTIV_WIN=$(xdotool getactivewindow getwindowpid)
    echo $ACTIV_WIN
    LAUNCH_WIN=$(ps -ef | grep “$BNAME” | grep -v grep | tr -s ' ' | cut -d' ' -f2)
    echo $LAUNCH_WIN
    for WIN in $LAUNCH_WIN; do
        if [ “$ACTIV_WIN” == “$WIN” ]; then
            # launched app is currently in focus, so minimize
            xdotool getactivewindow windowminimize
            exit
        else
            # launched app is not in focus, so raise and bring to focus
            for win in $(wmctrl -lx | tr -s ' ' | cut -d' ' -f1-3 | grep -i $BNAME | cut -d' ' -f1); do
                wmctrl -i -a $win
            done
        fi
    done
    exit
else
    # start it up
    $* &
fi

exit 0
