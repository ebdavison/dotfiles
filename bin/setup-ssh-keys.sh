#!/usr/bin/env bash

key_loaded() {
    local key="$1"
    local fp
    fp=$(ssh-keygen -lf "$key" | awk '{print $2}') || return 1
    ssh-add -l | awk '{print $2}' | grep -Fxq "$fp"
}

source ~/.bashrc.d/ssh-find-agent.bashrc

ssh-find-agent -a
if [ ! $? ]
then
	echo "executing ssh-agent"
	eval $(ssh-agent)
else
	echo "ssh-agent already loaded"
fi

if key_loaded ~/.ssh/id_rsa
then
	echo "~/.ssh/id_rsa already loaded"
else
	ssh-add /.ssh/id_rsa
fi

if key_loaded ~/.ssh/eddaviso-rsa-key-20190829
then
	echo "~/.ssh/eddaviso-rsa-key-20190829 already loaded"
else
	ssh-add ~/.ssh/eddaviso-rsa-key-20190829
fi

if key_loaded ~/.ssh/contabo
then
	echo "~/.ssh/contabo already loaded"
else
	ssh-add ~/.ssh/contabo
fi
