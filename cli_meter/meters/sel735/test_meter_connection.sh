#!/bin/bash

#################################
# This script:
# - checks the connection to the meter
# - is called from data_pipeline.sh
# - uses environment variables
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 1 ]; then
    fail "Usage: $0 <meter_ip>"
fi

# Logging in to the FTP server and checking the connection using lftp

lftp_output=$(lftp -u $USERNAME,$PASSWORD -e "pwd; bye" $meter_ip)

if [ "$?" -eq 0 ]; then
    log "Successful connection test to meter: $meter_ip"
    return 0
else
    fail "The FTP service is not available, and the connection was not established. Check for multiple connections to the meter: $meter_ip"
fi
