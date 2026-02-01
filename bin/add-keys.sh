#!/bin/bash

# echo $SSH_AUTH_SOCK
# echo $SSH_AGENT_PID

# contabo
ssh-add $HOME/.ssh/eddaviso-rsa-key-20190829
ssh-add $HOME/.ssh/hunt_id_rsa
# id_ed25519
ssh-add $HOME/.ssh/id_rsa
# strider.pem
# voterfraudhub.pem
