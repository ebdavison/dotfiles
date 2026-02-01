#!/usr/bin/env bash

nmcli conn down id "Wired connection 3"
nmcli conn down be8c35f2-6921-44c1-84e6-dd8f14acc421

nmcli conn down id "Talos"
nmcli conn down 2f34f212-b7e2-34f1-9d1d-063a1f6d49a0

#nmcli conn down id "TalosWired"

nmcli conn up id "Home"
nmcli conn up 3f99dfc9-e033-31a3-96e9-e9222edd0fed

#sudo route add default gw 10.211.1.1
route -n
