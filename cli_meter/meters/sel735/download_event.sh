#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    fail "Usage: $0 <meter_ip> <event_id> <output_dir>"
fi

# Extracting arguments into variables
meter_ip=$1
event_id=$2
download_dir="$3/$event_id" # Assumes $3 = /../location/data_type/YYYY-MM/METER_ID/working
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
