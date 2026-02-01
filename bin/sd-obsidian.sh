#!/bin/bash

logfile=/tmp/sd.log

echo "------------" >> $logfile
date >> $logfile

pgrep -x obsidian > /dev/null 
rc=$?
echo "rc: $rc" >> $logfile

if [ $rc -eq 0 ]
then
	echo "cmd: xdotool search --name '^.*Obsidian v' windowactivate" >> /tmp/sd.log
	xdotool search --name '^.*Obsidian v' windowactivate
else
	echo "cmd: flatpak run md.obsidian.Obsidian &" >> /tmp/sd.log
	flatpak run md.obsidian.Obsidian >> /tmp/sd.log
fi

date >> $logfile
echo "------------" >> $logfile
