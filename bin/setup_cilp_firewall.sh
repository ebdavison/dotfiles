#!/bin/bash

#hostIP=192.168.50.1
#hostIP=10.211.2.126
hostIP=192.168.120.1
#vmInterfaceToHost=enp0s3
#vmInterfaceToHost=enp1s0
vmInterfaceToHost=enp6s0
#vmIP=192.168.50.200
#vmIP=10.211.2.133
#vmIP=192.168.122.129
vmIP=192.168.120.252
tunnelInterface=cscotun0

########################################################################
# These first few things just allow access from the host OS in to the VM
########################################################################

# make sure we don't have a route to the host OS through the tunnel

if ip route | grep $hostIP | grep $tunnelInterface >/dev/null 2>&1
then
  echo "Deleting host OS route through the tunnel"
  sudo ip route delete $hostIP dev $tunnelInterface
fi

# add a more specific route to the host OS to avoid that traffic going into the 
VPN
if ! ip route | grep $hostIP | grep $vmInterfaceToHost >/dev/null 2>&1
then 
  echo "Adding host OS route around the tunnel"
  sudo ip route add $hostIP dev $vmInterfaceToHost
fi

# tell iptables to let us in
if ! sudo iptables -C ciscovpn -s $hostIP/32 -d $vmIP/32 -i $vmInterfaceToHost -
j ACCEPT >/dev/null 2>&1 
then 
  echo "Allowing host OS access in iptables"
  sudo iptables -I ciscovpn 8 -s $hostIP/32 -d $vmIP/32 -i $vmInterfaceToHost -j
 ACCEPT
fi

####################################################################
# Everything below here is for masquerading traffic from the host OS
# through the VPN running in the VM
####################################################################

if [[ `sysctl -n net.ipv4.ip_forward` == 0 ]]
then
   echo "setting net.ipv4.ip_forward=1"
   sudo sysctl -w net.ipv4.ip_forward=1
fi

if ! sudo iptables -t nat -C POSTROUTING -s $hostIP/32 -o $tunnelInterface -j MA
SQUERADE >/dev/null 2>&1
then
  echo "Setting up masquerading in iptables"
  sudo iptables -t nat -I POSTROUTING -s $hostIP/32 -o $tunnelInterface -j MASQU
ERADE
fi

if ! sudo iptables -C ciscovpn -i $vmInterfaceToHost -o $tunnelInterface -m stat
e --state RELATED,ESTABLISHED -j ACCEPT >/dev/null 2>&1
then
  echo "allowing established in iptables"
  sudo iptables -I ciscovpn 9 -i $vmInterfaceToHost -o $tunnelInterface -m state
 --state RELATED,ESTABLISHED -j ACCEPT
fi

if ! sudo iptables -C ciscovpn -i $vmInterfaceToHost -o $tunnelInterface -j ACCE
PT >/dev/null 2>&1
then
  echo "allowing traffic from $vmInterfaceToHost to $tunnelInterface in iptables
" 
  sudo iptables -I ciscovpn 10 -i $vmInterfaceToHost -o $tunnelInterface -j ACCE
PT
fi


