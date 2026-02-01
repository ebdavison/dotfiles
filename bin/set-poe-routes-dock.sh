#!/bin/bash

cd "/home/edavison/Games/path-of-exile/drive_c/Program Files (x86)/Grinding Gear Games/Path of Exile"
grep "Connecting to instance server" logs/Client.txt | gawk '{print $NF}' | sort -u | cut -f 1 -d : | cut -f 1-3 -d \. | sort -u > /tmp/poe-nets.txt
for NET in $(cat /tmp/poe-nets.txt)
do
	# echo $NET
	CNET="$NET.0/24"
	echo "Adding route for $CNET"
	sudo route add -net $CNET gateway 10.211.2.1 dev enp0s13f0u2u3
done

for HOST in dal01.login.pathofexile.com patchcdn.pathofexile.com 173.237.8.108
do
	sudo route add -host $HOST gateway 10.211.2.1 dev enp0s13f0u2u3
done

