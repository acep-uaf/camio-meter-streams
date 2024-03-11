#!/bin/bash

#################################
# Download files for a specific event from the meter
# 
######################################################
# This script is called from update_event_files.sh and accepts 2 arguments:
# 1. METER_IP (env?)
# 2. event_id
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <METER_IP> <EVENT_ID>"
    exit 1
fi

# Extracting arguments into variables
METER_IP=$1
EVENT_ID=$2
LOCAL_FULL_PATH="$DATA_TYPE/$METER_ID/level0/$EVENT_ID"

# Create the local directory for this event if it doesn't exist
mkdir -p "$LOCAL_FULL_PATH"
if [ $? -eq 0 ]; then
    log "Created local directory for event: $EVENT_ID"
else
    log "Failed to create local directory for event: $EVENT_ID" "err"
    exit 1
fi
 
# Single lftp session
lftp -u "$USERNAME,$PASSWORD" "$METER_IP" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $LOCAL_FULL_PATH
mget *$EVENT_ID*.*
bye
EOF

# Check the exit status of the lftp command
if [ $? -eq 0 ]; then
    log "Files downloaded for event: $EVENT_ID"
else
    log "Failed to download files for event: $EVENT_ID" "err"
    exit 1
fi

echo "Download complete for event: $EVENT_ID"
