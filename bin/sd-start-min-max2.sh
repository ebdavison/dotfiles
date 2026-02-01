#!/bin/bash
# Find_app
# Author: Lucas van Staden (lvs at dedmeet.com / www.dedmeet.com)
# This little script will try and find the application attempting to start
# in the running processes, and if found, focus the application
# if not found, a new instance will start
# usage:
# find_app.sh <application with full path>
# params
# 1 - application to start (full path)
# helper applications
#!/bin/bash
# Find_app
# Author: Lucas van Staden (lvs at dedmeet.com / www.dedmeet.com)
# This little script will try and find the application attempting to start
# in the running processes, and if found, focus the application
# if not found, a new instance will start
# usage:
# find_app.sh <application with full path>
# params
# 1 - application to start (full path)
# helper applications
DOLLARONE=$(echo $1 | sed -e 's/[\t ]*$//') #Delete trailing spaces
WMCTRL=$(which wmctrl)
GREP=$(which grep)
APPLICATION=$(echo $DOLLARONE | cut -d ' ' -f 1)
if [ "x$APPLICATION" != "x$DOLLARONE" ]; then
    APPARGS=$(echo $DOLLARONE | cut -d ' ' -f 2)
fi
BASENAME=$(basename $APPLICATION)
BASENAME=$(echo $BASENAME | tr "[:upper:]" "[:lower:]")
FOUND=0
function findwindow {
    # 1 = BASENAME
    # 2 = WMCTRL
    # 3 = GREP
    IFS=$'\n'
    for RUNNING in $($2 -l -x); do
        if [ $(echo $RUNNING | tr "[:upper:]" "[:lower:]" | $3 -c $DOLLARONE) -gt 0 ]; then
            HOSTNAME=$(hostname)
            WINDOW=${RUNNING#*${HOSTNAME} }
            $2 -a $WINDOW
            FOUND=1
        fi
    done
}
if [ "x$APPARGS" = "x" ]; then
    findwindow $BASENAME $WMCTRL $GREP
    if [ $FOUND -eq 0 ]; then
        if [ "$APPLICATION" = "mattermost" ]; then
            # /opt/Data/Software/mattermost-desktop-4.6.2-linux-x86_64.AppImage &
	    # /opt/Data/Software/mattermost-desktop-5.3.1-linux-x86_64.AppImage &
	    flatpak run com.mattermost.Desktop &
	    # /usr/bin/mattermost-desktop &
        else
            $APPLICATION &
        fi
        sleep 2
        # Try and find the application, after opened
        findwindow $BASENAME $WMCTRL $GREP
        if [ $FOUND -eq 0 ]; then
            # Still not found, wait a bit more, and try again
            sleep 3
            findwindow $BASENAME $WMCTRL $GREP
        fi
    fi
else
    $APPLICATION $APPARGS &
fi
