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
#   bandwidth_limit   Optional: Bandwidth limit for the connection
#                     (default is 0)
#
# Requirements:       lftp
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check if at least 1 argument is passed
[ "$#" -lt 1 ] && failure $EXIT_INVALID_ARGS "Usage: $script_name <meter_ip> [bandwidth_limit]"

meter_ip="$1"
bandwidth_limit="${2:-0}" # If not set default to 0

# Logging in to the FTP server and checking the connection using lftp
lftp_output=$(lftp -u $USERNAME,$PASSWORD -e "set net:limit-rate $bandwidth_limit; ls; bye" $meter_ip)
lftp_exit_code=$?

[ "$lftp_exit_code" -eq 0 ] && log "Successful connection test to meter: $meter_ip"|| failure $EXIT_LFTP_FAIL "Connection Unsuccessful to meter: $meter_ip"


