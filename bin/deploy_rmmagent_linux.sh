#!/bin/bash

for f in storage.retirementprosperitygroup.com www.otcommittee.com 
do
	echo "copying rmmagent to $f"
	user=edavison
	scp /opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent/rmmagent $user@$f:
done

for f in mail.amzwiz.com 
do
	echo "copying rmmagent to $f"
	user=adminebd
	scp /opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent/rmmagent $user@$f:
done

for f in mordor.edandmonique.org crypto.envisionedsoftware.com
do
	echo "copying rmmagent to $f"
	user=root
	scp /opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent/rmmagent $user@$f:
done
