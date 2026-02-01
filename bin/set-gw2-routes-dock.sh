#!/bin/bash

# cd "/home/edavison/Games/path-of-exile/drive_c/Program Files (x86)/Grinding Gear Games/Path of Exile"
# grep "Connecting to instance server" logs/Client.txt | gawk '{print $NF}' | sort -u | cut -f 1 -d : | cut -f 1-3 -d \. | sort -u > /tmp/poe-nets.txt

# for NET in $(cat /tmp/poe-nets.txt)
for NET in 65.24.40 
do
	# echo $NET
	CNET="$NET.0/24"
	echo "Adding route for $CNET"
	sudo route add -net $CNET gateway 10.211.1.1 dev enp0s20f0u12u3
	sudo route add -net $CNET gateway 10.211.1.1 dev enp0s13f0u1u3
	sudo route add -net $CNET gateway 10.211.1.1 dev enp0s13f0u2u3
	sudo route add -net $CNET gateway 10.211.1.1 dev enp0s31f6
done

for HOST in assetcdn.101.arenanetworks.com cligate.101.ncplatform.net gemstore-live.ncplatform.net ncplatform.net cms-live.ncplatform.net exchange-live.ncplatform.net www.guildwars2.com tradingpost-live.ncplatform.net a.cdn.ua.ncsoft.com ncsoft-router.com ncsoft.com guildwars2.com
do
	sudo route add -host $HOST gateway 10.211.1.1 dev enp0s20f0u12u3
	sudo route add -host $HOST gateway 10.211.1.1 dev enp0s13f0u1u3
	sudo route add -host $HOST gateway 10.211.1.1 dev enp0s13f0u2u3
	sudo route add -host $HOST gateway 10.211.1.1 dev enp0s31f6
done

