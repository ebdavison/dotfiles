#!/bin/bash

cd /opt/Data/Personal/NextCloud/Documents/IT/repos/rmmagent
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w"
