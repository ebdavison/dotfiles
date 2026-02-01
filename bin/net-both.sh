#!/usr/bin/env bash

nmcli conn down id "Wired connection 3"
nmcli conn down be8c35f2-6921-44c1-84e6-dd8f14acc421

nmcli conn up id "Home"
nmcli conn up 3f99dfc9-e033-31a3-96e9-e9222edd0fed

nmcli conn up id "Talos"
nmcli conn up 2f34f212-b7e2-34f1-9d1d-063a1f6d49a0

#sudo route del -net 0.0.0.0 gw 10.7.124.217 dev enp0s13f0u1u1i5
sudo route del -net 0.0.0.0 gw 10.7.124.217 dev if-talos
sudo route del -net 0.0.0.0 gw 10.7.124.217 dev enp0s13f0u1u2u3
#sudo route add -net 0.0.0.0 gw 10.211.1.1 dev enp0s31f6
sudo route add -net 0.0.0.0 gw 10.211.1.1 dev if-home
sudo route add -net 0.0.0.0 gw 10.211.1.1 dev enp0s31f6

sudo route del -net 0.0.0.0 gateway 10.7.124.217 dev enp0s13f0u1u2u3
sudo route del -net 0.0.0.0 gateway 10.7.124.217 dev enp0s13f0u2u2u3

$HOME/bin/setup-cisco-routes-rev.sh
route -n

