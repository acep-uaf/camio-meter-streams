#!/bin/bash
# ==============================================================================
# Script Name:        test_meter_connection.sh
# Description:        This script checks the connection to the meter
#                     via FTP using provided environment variables.
#
# Usage:              ./test_meter_connection.sh <meter_ip> [bandwidth_limit] [max_retries]
# Called by:          download.sh
#
# Arguments:
#   meter_ip          IP address of the meter
#   bandwidth_limit   Optional: Bandwidth limit for the connection
#                     (default is 0/unlimited)
#   max_retries       Optional: Maximum number of retries for the connection
#                     (default is 1)
#
# Requirements:       lftp
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check if at least 1 argument is passed
[ "$#" -lt 1 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_ip> [bandwidth_limit] [max_retries]"

meter_ip="$1"
bandwidth_limit="${2:-0}"
max_retries="${3:-1}"

# Set intervals between lftp connection attempts (s)
reconnect_interval_base=5

# Logging in to the FTP server and checking the connection using lftp
lftp_output=$(lftp -u $USERNAME,$PASSWORD $meter_ip <<END_FTP_SESSION
    set net:max-retries $max_retries;
    set net:reconnect-interval-base $reconnect_interval_base;
    set net:limit-rate $bandwidth_limit;
    ls;
    bye
END_FTP_SESSION
)

lftp_exit_code=$?

[ "$lftp_exit_code" -eq 0 ] && log "Successful connection test to meter: $meter_ip"|| failure $STREAMS_LFTP_FAIL "Connection Unsuccessful to meter: $meter_ip"


