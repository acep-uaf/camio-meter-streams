#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <meter_ip> <event_id> <output_dir>"
    exit 1
fi

# Extracting arguments into variables
meter_ip=$1
event_id=$2
download_dir="$3/level0/$event_id"
download_progress_dir="$3/.download_progress"
remote_dir="EVENTS"

# LOCATION/DATA_TYPE/YYYY-MM/METER_ID/level0/

# Define directories for tracking download status within the specified output directory
mkdir -p "$download_progress_dir/in_progress" "$download_progress_dir/completed"

# Function to mark an event as in progress
mark_as_in_progress() {
    touch "$download_progress_dir/in_progress/$event_id"
}

# Function to mark an event as completed
mark_as_completed() {
    mv "$download_progress_dir/in_progress/$event_id" "$download_progress_dir/completed/$event_id"
}


# Create the local directory for this event if it doesn't exist
mkdir -p "$download_dir"
if [ $? -eq 0 ]; then
    log "Created local directory for event: $event_id from script: $(basename "$0")"
else
    log "Failed to create local directory for event: $event_id" "err"
    exit 1
fi

# Mark the event as in progress
mark_as_in_progress 

# Single lftp session
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $remote_dir
lcd $download_dir
mget *$event_id*.*
bye
EOF

# Check the exit status of the lftp command
if [ $? -eq 0 ]; then
    log "Files downloaded for event: $event_id"
    mark_as_completed
else
    log "Failed to download files for event: $event_id" "err"
    exit 1
fi

echo "Download complete for event: $event_id"
