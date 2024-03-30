#!/bin/bash

CISCO_NETS="10.22.31.77/32 10.83.92.0/24 10.83.192.0/24 10.115.70.0/24 10.123.173.0/24 18.204.156.250/32 54.175.232.95/32 64.100.0.0/14 64.104.0.0/16 72.163.0.0/16 149.96.0.0/16 172.18.151.0/24 173.36.0.0/14 199.91.136.0/21 173.73.0.0/16"
MS_NETS="13.64.0.0/11 13.96.0.0/13 13.104.0.0/14 20.180.0.0/14 20.184.0.0/13 23.96.0.0/13 40.76.0.0/14 40.80.0.0/12 40.96.0.0/12 40.112.0.0/13 40.120.0.0/14 40.124.0.0/16 40.125.0.0/17 40.126.0.0/18 104.208.0.0/13"
NETS="$CISCO_NETS $MS_NETS"

BLIZDEV=wlp2s0
BLIZIP=$(ifconfig $BLIZDEV | awk '/inet / {print $2}')
#BLIZGW=$(ip route list dev $BLIZDEV | grep $BLIZIP)
BLIZGW=$(ip route list dev $BLIZDEV | grep default | awk '{print $3}')

#BLIZIP="10.99.11.17"

for net in $NETS; do
	#ip route add "$net" via $BLIZIP dev $BLIZDEV
	ip route add "$net" via $BLIZGW dev $BLIZDEV
done

# heimdall
#ip route add 34.197.225.206 via $BLIZIP dev $BLIZDEV
ip route add 34.197.225.206 via $BLIZGW dev $BLIZDEV

#ifconfig del 0.0.0.0 netmask 0.0.0.0 gw $BLIZGW
ip route del default dev $BLIZDEV

