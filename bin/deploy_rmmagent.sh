#!/bin/bash

sudo systemctl stop tacticalagent
sudo cp rmmagent /usr/local/bin/tacticalagent 
sudo systemctl start tacticalagent

