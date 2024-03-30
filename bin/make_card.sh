#!/bin/bash
cat $1 | pstops -pletter -b "4:3U@.5(1w,1h)+0U@.5(.5w,1h)+1@.5(0,0)+2@.5(.5w,0)" > $2
