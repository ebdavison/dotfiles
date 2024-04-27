#!/usr/bin/env bash

eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/eddaviso-rsa-key-20190829
ssh-add ~/.ssh/contabo
