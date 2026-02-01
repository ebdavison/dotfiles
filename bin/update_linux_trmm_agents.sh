#!/bin/bash

AGENT_DIR=/opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent

#for host in storage.retirementprosperitygroup.com mordor.edandmonique.org www.otcommittee.com crypto.envisionedsoftware.com mail.amzwiz.com localhost
#for host in mordor.edandmonique.org 
#for host in www.otcommittee.com crypto.envisionedsoftware.com mail.amzwiz.com localhost
#for host in localhost
for host in storage.retirementprosperitygroup.com www.otcommittee.com crypto.envisionedsoftware.com mail.amzwiz.com localhost 10.211.1.2 webs.edandmonique.org box.edandmonique.org
do
	echo Installing rmm agent to $host
	scp -i $HOME/.ssh/eddaviso-rsa-key-20190829 $AGENT_DIR/rmmagent root@$host:
	scp -i $HOME/.ssh/eddaviso-rsa-key-20190829 $HOME/bin/deploy_rmmagent.sh root@$host:
	ssh -i $HOME/.ssh/eddaviso-rsa-key-20190829 root@$host "chmod +x deploy_rmmagent.sh"
	ssh -i $HOME/.ssh/eddaviso-rsa-key-20190829 root@$host "./deploy_rmmagent.sh"
done

