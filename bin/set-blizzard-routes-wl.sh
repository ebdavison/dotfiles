#!/bin/bash

#cd "/home/edavison/Games/path-of-exile/drive_c/Program Files (x86)/Grinding Gear Games/Path of Exile"
# grep "Connecting to instance server" logs/Client.txt | gawk '{print $NF}' | sort -u | cut -f 1 -d : | cut -f 1-3 -d \. | sort -u > /tmp/poe-nets.txt
#for NET in $(cat /tmp/poe-nets.txt)
NETS=''
for NET in $NETS
do
	# echo $NET
	CNET="$NET.0/24"
	echo "Adding route for $CNET"
	sudo route add -host $CNET gateway 10.211.2.1 dev wlp2s0
done

#for HOST in dal01.login.pathofexile.com patchcdn.pathofexile.com 173.237.8.108
for HOST in 24.105.30.129 level3.blizzard.com download.blizzard.com us.cdn.blizzard.com us.actual.battle.net download.blizzard.com.c.footprint.net us.battle.net prod.depot.battle.net alert-us.battle.net us.launcher.battle.net nydus.battle.net telemetry-in.battle.net 
do
	sudo route add -host $HOST gateway 10.211.2.1 dev wlp2s0 
done

