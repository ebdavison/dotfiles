#!/usr/bin/env bash

logfile=/tmp/sd.log

echo "------------" >> $logfile
date >> $logfile

pgrep -f squirrel-sql > /dev/null 
rc=$?
echo "rc: $rc" >> $logfile

if [ $rc -eq 0 ]
then
	echo "cmd: xdotool search --name '^.*SQuirreL SQL Client' windowactivate" >> /tmp/sd.log
	xdotool search --name '^.*SQuirreL SQL Client' windowactivate
else
	echo "cmd: flatpak run md.obsidian.Obsidian &" >> /tmp/sd.log
	#flatpak run net.sourceforge.squirrel_sql >> /tmp/sd.log
	/usr/bin/env squirrel-sql &
fi

date >> $logfile
echo "------------" >> $logfile
