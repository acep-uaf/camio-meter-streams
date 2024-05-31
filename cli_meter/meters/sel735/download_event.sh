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
#                     commons.sh
# ==============================================================================

# Check if the correct number of arguments are passed
if [ "$#" -ne 4 ]; then
    fail "Usage: $0 <meter_ip> <event_id> <output_dir>"
fi

# Extracting arguments into variables
meter_ip=$1
event_id=$2
download_dir="$3/$event_id" # Assumes $3 = /../location/data_type/YYYY-MM/METER_ID/working
bandwidth_limit=$4
remote_dir="EVENTS"

# Create the local directory for this event if it doesn't exist
mkdir -p "$download_dir"
if [ $? -eq 0 ]; then
    log "Created local directory for event: $event_id"
else
    fail "Failed to create local directory for event: $event_id"
fi

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
if [ $? -eq 0 ]; then
    log "Download complete for event: $event_id"
else
    fail "Failed to download files for event: $event_id"
fi
