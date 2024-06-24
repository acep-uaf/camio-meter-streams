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
    log "Usage: $0 <meter_ip> [bw_limit]"
    exit $EXIT_INVALID_ARGS 
fi

meter_ip="$1"
bw_limit="${2:-0}"  # Default to 0 if bw_limit is not provided

# Check if meter_ip is provided
if [ -z "$meter_ip" ]; then
    log "Meter IP address must be specified"
    exit $EXIT_INVALID_ARGS
fi

# Logging in to the FTP server and checking the connection using lftp
lftp_output=$(lftp -u $USERNAME,$PASSWORD -e "set net:limit-rate $bw_limit; ls; bye" $meter_ip)

if [ "$?" -eq 0 ]; then
    log "Successful connection test to meter: $meter_ip"
else
    log "The FTP service is not available, and the test connection was not established."
    log "Check that the ip address is correct and for multiple connections to: $meter_ip"
    exit $EXIT_LFTP_FAIL 
fi
