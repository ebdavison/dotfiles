#!/bin/bash

nmcli conn down id "Home"
nmcli conn up id "Talos"
route -n
