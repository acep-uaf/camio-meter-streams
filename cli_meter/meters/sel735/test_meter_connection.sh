#!/bin/bash
# ==============================================================================
# Script Name:        test_meter_connection.sh
# Description:        This script checks the connection to the meter
#                     via FTP using provided environment variables.
#
# Usage:              ./test_meter_connection.sh <meter_ip>
# Called by:          download.sh
#
# Arguments:
#   meter_ip          IP address of the meter
#
# Requirements:       lftp
#                     commons.sh
# ==============================================================================

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    fail "Usage: $0 <meter_ip> <bandwidth_limit>"
fi

# Logging in to the FTP server and checking the connection using lftp
lftp_output=$(lftp -u $USERNAME,$PASSWORD -e "set net:limit-rate $bandwidth_limit; ls; bye" $meter_ip)

if [ "$?" -eq 0 ]; then
    log "Successful connection test to meter: $meter_ip"
    return 0
else
    fail "The FTP service is not available, and the connection was not established. Check for multiple connections to the meter: $meter_ip"
fi
