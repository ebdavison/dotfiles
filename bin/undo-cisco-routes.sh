#!/bin/bash

cd /home/edavison/bin

if [ -e routes-env.txt ]; then
	source routes-env.txt
fi

# NATDEV=virbr0
NATDEV=virbr0

if [ "x$OS_TYPE" = "xLinux" ]; then
  #NATIP=$(ip addr show dev wlp2s0 | awk '/inet / {print $2}')
  NATIP=$(ip addr show dev $NATDEV | awk '/inet / {print $2}')
  NATIP=${NATIP/\/*/}
else
  NATIP=$(ifconfig $NATDEV | awk '/inet / {print $2}')
fi

echo NATIP $NATIP

# route -n | grep 10.211.2.126 | gawk '{print "route del -net " $1 " gw " $2 " netmask " $3 " dev " $8}' | sudo bash
route -n | grep 10.211.1.14 | gawk '{print "route del -net " $1 " gw " $2 " netmask " $3 " dev " $8}' | sudo bash
route -n | grep 192.168.120.252 | gawk '{print "route del -net " $1 " gw " $2 " netmask " $3 " dev " $8}' | sudo bash
route -n | grep $NATIP | gawk '{print "route del -net " $1 " gw " $2 " netmask " $3 " dev " $8}' | sudo bash
