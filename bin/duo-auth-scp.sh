#!/bin/bash

#duo-sso -interactive && rsync -avPHx ~/.aws/credentials hal:.aws/
duo-sso -interactive && rsync -avPHx ~/.aws/credentials hunter:.aws/

