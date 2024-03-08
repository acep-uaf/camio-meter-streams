#!/bin/bash

#################################
# 
# 
######################################################
# This script is called from download.sh and accepts 3 arguments:
# 1. meter_ip
# 2. event_id
# 3. path
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <meter_ip> <event_id> <output_dir>"
    exit 1
fi

# Extracting arguments into variables
meter_ip=$1
event_id=$2
output_dir="$3/level0/$event_id"
# LOCATION/DATA_TYPE/YYYY-MM/METER_ID/level0/event_id

# Create the local directory for this event if it doesn't exist
mkdir -p "$output_dir"
if [ $? -eq 0 ]; then
    log "Created local directory for event: $event_id"
else
    log "Failed to create local directory for event: $event_id" "err"
    exit 1
fi
 
# Single lftp session
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $output_dir
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
