#!/bin/bash
# ==============================================================================
# Script Name:        download_event.sh
# Description:        This script downloads event files from the meter
#                     via FTP and saves them in the specified output directory.
#
# Usage:              ./download_event.sh <meter_ip> <event_id> <output_dir>
# Called by:          download.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   event_id          ID of the event to download
#   output_dir        Directory where the event files will be saved
#
# Requirements:       lftp
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check if the correct number of arguments are passed
[ "$#" -lt 3 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_ip> <event_id> <output_dir> [bandwidth_limit]"

# Extracting arguments into variables
meter_ip=$1
event_id=$2
download_dir="$3/$event_id" # Assumes $3 = /../location/data_type/YYYY-MM/METER_ID/working
bandwidth_limit="${4:-0}"
remote_dir="EVENTS"

# Create the local directory for this event if it doesn't exist
mkdir -p "$download_dir" && log "Created local directory for event: $event_id" || failure $STREAMS_DIR_CREATION_FAIL "Failed to create local directory for event: $event_id"

# Single lftp session
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<END_FTP_SESSION
set xfer:clobber on
set net:limit-rate $bandwidth_limit
cd $remote_dir
lcd $download_dir
mget *$event_id*.*
bye
END_FTP_SESSION

# Check the exit status of the lftp command
lftp_exit_code=$?
[ $lftp_exit_code -eq 0 ] && log "Download complete for event: $event_id" || failure $STREAMS_LFTP_FAIL "Failed to download files for event: $event_id"
