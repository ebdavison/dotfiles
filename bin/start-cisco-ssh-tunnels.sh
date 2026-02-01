#!/bin/bash

~/bin/ssh-tunnel-manager.sh start "rds-pg"
~/bin/ssh-tunnel-manager.sh start "heimdall-proxy"
~/bin/ssh-tunnel-manager.sh start "hal-django-8123"
~/bin/ssh-tunnel-manager.sh start "airflow-webserver"
~/bin/ssh-tunnel-manager.sh start "airflow-flower"


