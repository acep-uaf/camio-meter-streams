#!/bin/bash

#################################
# This script:
# - checks the connection to the meter
# - is called from data_pipeline.sh
# - uses environment variables
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <meter_ip>"
    exit 1
fi

# Logging in to the FTP server and checking the connection using lftp

lftp_output=$(lftp -u $USERNAME,$PASSWORD -e "pwd; bye" $meter_ip)
lftp_exit_status=$?

if [ "$lftp_exit_status" -eq 0 ]; then
    echo "Successful connection test to meter: $meter_ip"
    return 0
else
    echo "The FTP service is not available, and the connection was not established. Check for multiple connections to the meter: $meter_ip"
    log "FTP Server IP: $meter_ip is not available." "err"
    return 1
fi


