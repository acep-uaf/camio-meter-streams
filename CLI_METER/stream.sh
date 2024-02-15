#!/bin/bash

while true; do
    rsync -a test stream@10.25.157.75:/home/stream/data
    sleep 60
done


# set up ssh key 
# create lock file check for lock file 
# echo timestamp 
# log file have rsync command to send what it did to log file
# system d process
# script will be service to start and stop 

