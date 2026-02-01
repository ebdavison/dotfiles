#!/bin/bash

sudo route del -net 0.0.0.0 gw 10.211.1.1

sudo ip route add 10.211.1.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add default via 10.211.1.1 dev enp0s31f6 table rt2
sudo ip rule add from 10.211.1.4/32 table rt2
sudo ip rule add to 10.211.1.4/32 table rt2

#sudo route add -net 10.211.1.0 netmask 255.255.255.0 gw 10.211.1.1 table rt2
sudo ip route add 10.211.1.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 10.211.99.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 10.211.199.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 192.168.1.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 192.168.2.0/24 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 74.208.183.193/32 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 108.175.14.254/32 dev enp0s31f6 src 10.211.1.4 table rt2
sudo ip route add 142.93.177.120/32 dev enp0s31f6 src 10.211.1.4 table rt2

#sudo route del -net 10.211.1.0 gw 0.0.0.0 netmask 255.255.255.0
#sudo route add -net 10.211.2.0 netmask 255.255.255.0 gw 10.211.1.1 table rt2
sudo ip route add 10.211.2.0/24 dev enp0s31f6 src 10.211.1.4 table rt2

#sudo route add -net 10.1.10.0 netmask 255.255.255.0 gw 10.211.1.1 table rt2
sudo ip route add 10.1.10.0/24 dev enp0s31f6 src 10.211.1.4 table rt2

# my home IP
#sudo route add 76.183.146.8 gw 10.211.1.1 
sudo ip route add 76.183.146.8/32 dev enp0s31f6 src 10.211.1.4 table rt2

# my mail server
#sudo route add 104.131.2.122 gw 10.211.1.1
sudo ip route add 104.131.2.122/32 dev enp0s31f6 src 10.211.1.4 table rt2
#sudo route add 68.183.58.15 gw 10.211.1.1
sudo ip route add 68.183.58.15/32 dev enp0s31f6 src 10.211.1.4 table rt2

# blizzard (game)
#sudo route add 12.129.222.10 gw 10.211.1.1
sudo ip route add 12.129.222.10/32 dev enp0s31f6 src 10.211.1.4 table rt2

# envisionedsoftware.com
#sudo route add 74.208.183.193 gw 10.211.1.1
sudo ip route add 74.208.183.193/32 dev enp0s31f6 src 10.211.1.4 table rt2
#sudo route add 108.175.14.254 gw 10.211.1.1
sudo ip route add 108.175.14.254/32 dev enp0s31f6 src 10.211.1.4 table rt2

# RPG
#sudo route add 76.99.124.49 gw 10.211.1.1 
sudo ip route add 76.99.124.49/32 dev enp0s31f6 src 10.211.1.4 table rt2
#sudo route add 45.79.182.194 gw 10.211.1.1 
sudo ip route add 45.79.182.194/32 dev enp0s31f6 src 10.211.1.4 table rt2

# google gmail
#sudo route add 142.250.115.108 gw 10.211.1.1 
sudo ip route add 142.250.115.108/32 dev enp0s31f6 src 10.211.1.4 table rt2
#sudo route add 142.250.115.109 gw 10.211.1.1 
sudo ip route add 142.250.115.109/32 dev enp0s31f6 src 10.211.1.4 table rt2

# commands for showing routes
# ip route list table rt2
# ip rule show

