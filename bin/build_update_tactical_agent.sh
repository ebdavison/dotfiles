#!/bin/bash

AGENT_DIR=/opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent

cd $AGENT_DIR
git pull
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o rmmagent

