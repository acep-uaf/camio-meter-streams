#!/bin/bash

######################################################
# Downloads event files from a remote meter to a specified local directory.
# Usage: (call from download.sh) ./download_event.sh <meter_ip> <event_id> <output_dir>
# - meter_ip: IP address of the  meter.
# - event_id: Identifier of the event to download.
# - output_dir: Base directory for downloads, final path includes /level0/event_id.
# Requires 'lftp', USERNAME, and PASSWORD for FTP access.
# Constructs and downloads to: output_dir/YYYY-MM/METER_ID/level0/event_id
######################################################

REMOTE_METER_PATH="EVENTS"

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <meter_ip> <event_id> <output_dir>"
    exit 1
fi

# Extracting arguments into variables
meter_ip=$1
event_id=$2
download_dir="$3/level0/$event_id"

# LOCATION/DATA_TYPE/YYYY-MM/METER_ID/level0/event_id

# Create the local directory for this event if it doesn't exist
mkdir -p "$download_dir"
if [ $? -eq 0 ]; then
    log "Created local directory for event: $event_id from script: $(basename "$0")"
else
    log "Failed to create local directory for event: $event_id" "err"
    exit 1
fi
 
# Single lftp session
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $download_dir
mget *$event_id*.*
bye
EOF

# Check the exit status of the lftp command
if [ $? -eq 0 ]; then
    log "Files downloaded for event: $event_id"
else
    log "Failed to download files for event: $event_id" "err"
    exit 1
fi

echo "Download complete for event: $event_id"
