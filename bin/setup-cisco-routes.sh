#!/usr/bin/env bash

OS_TYPE=$(uname -s)

IFS=" "

# Cisco VPN endpoints:
#CISCO_NETS="10.22.31.77/32 10.83.92.0/24 10.83.192.0/24 10.115.70.0/24 10.123.173.0/24 18.204.156.250/32 54.175.232.95/32 64.100.0.0/14 64.104.0.0/16 72.163.0.0/16 149.96.0.0/16 171.70.0.0/15 172.18.151.0/24 173.36.0.0/14 199.91.136.0/21"
CISCO_NETS="10.22.31.77/32 10.83.92.0/24 10.83.192.0/24 10.115.70.0/24 10.123.173.0/24 18.204.156.250/32 54.175.232.95/32 64.100.0.0/14 64.104.0.0/16 72.163.0.0/16 149.96.0.0/16 172.18.151.0/24 173.36.0.0/14 199.91.136.0/21 10.7.22.0/24 10.7.30.0/24"

HUNT_NETS="10.85.206.0/24 10.85.207.0/24"

MS_NETS="13.64.0.0/11 13.96.0.0/13 13.104.0.0/14 23.96.0.0/13 40.76.0.0/14 40.80.0.0/12 40.96.0.0/12 40.112.0.0/13 40.120.0.0/14 40.124.0.0/16 40.125.0.0/17 40.126.0.0/18 104.208.0.0/13 52.96.66.194/32 20.0.0.0/8"

AWS_STUFF="52.61.166.51/32 160.1.173.82/32"

NETS="$CISCO_NETS $MS_NETS $AWS_STUFF $HUNT_NETS"

cd /home/edavison/bin

# EBD
if [ -e routes-env.txt ]; then
	source routes-env.txt
fi

#NATIP=192.168.120.252
LOCALNATIP=10.211.1.14
#echo LOCALNATIP $LOCALNATIP

#NATDEV=wlp2s0
#NATDEV=virbr0
NATDEV=enp0s31f6

if [ "x$OS_TYPE" = "xLinux" ]; then
  #NATIP=$(ip addr show dev wlp2s0 | awk '/inet / {print $2}')
  NATIP=$(ip addr show dev $NATDEV | awk '/inet / {print $2}')
  NATIP=${NATIP/\/*/}
else
  NATIP=$(ifconfig $NATDEV | awk '/inet / {print $2}')
fi

echo NATIP $NATIP

if [ -n "$LOCALNATIP" ]; then
  NATIP=$LOCALNATIP
fi

#echo NATIP $NATIP

case $1 in 
    up) rtact=add
        ;;
    down) rtact=del
        ;;
esac

if [ "x$OS_TYPE" = "xLinux" ]; then
  for net in $NETS; do
    ip route ${rtact:-add} "$net" via $NATIP dev $NATDEV
  done 
elif [ "x$OS_TYPE" = "xDarwin"]; then
  for net in $NETS; do
    route ${rtact:-add} -net "$net" gateway $NATIP
  done
fi
