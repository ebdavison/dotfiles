#!/bin/bash

~/bin/ssh-tunnel-manager.sh stop "rds-pg"
~/bin/ssh-tunnel-manager.sh stop "heimdall-proxy"
~/bin/ssh-tunnel-manager.sh stop "hal-django-8123"
~/bin/ssh-tunnel-manager.sh stop "airflow-webserver"
~/bin/ssh-tunnel-manager.sh stop "airflow-flower"


