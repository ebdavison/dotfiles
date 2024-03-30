#!/bin/bash

ssh -f eddaviso@ec2-107-23-254-189.compute-1.amazonaws.com -L 8787:localhost:8787 -N
