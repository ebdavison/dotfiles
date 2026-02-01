#!/usr/bin/env bash

logfile=/tmp/sd.log

echo "------------" >> $logfile
date >> $logfile

pgrep -x code > /dev/null 
rc=$?
echo "rc: $rc" >> $logfile

if [ $rc -eq 0 ]
then
	echo "cmd: xdotool search --name '.*Visual Studio Code' windowactivate" >> $logfile
	xdotool search --name '.*Visual Studio Code' windowactivate
else
	echo "cmd: code" >> $logfile
	code >> $logfile
fi

date >> $logfile
echo "------------" >> $logfile
