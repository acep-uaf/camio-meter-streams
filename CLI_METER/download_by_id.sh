#!/bin/bash

# download_by_id.sh

source . utils.sh

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <FTP_METER_SERVER_IP> <EVENT_ID>"
    exit 1
fi

# Extracting arguments into variables
FTP_METER_SERVER_IP=$1
EVENT_ID=$2
LOG_FILE="log_download_by_id.log"
LOCAL_FULL_PATH="$LOCAL_PATH/$FTP_METER_ID/level0/$EVENT_ID"

# Create the local directory for this event if it doesn't exist
mkdir -p "$LOCAL_FULL_PATH"
if [ $? -eq 0 ]; then
    log "Created local directory for event $EVENT_ID."
else
    log "Failed to create local directory for event $EVENT_ID."
    exit 1
fi
 
# Single lftp session
lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$FTP_METER_SERVER_IP" <<EOF
set xfer:clobber on
cd $FTP_REMOTE_METER_PATH
lcd $LOCAL_FULL_PATH
mget *$EVENT_ID*.*
bye
EOF

# Check the exit status of the lftp command
if [ $? -eq 0 ]; then
    log "Successfully downloaded files for event $EVENT_ID."
else
    log "Failed to download files for event $EVENT_ID."
    exit 1
fi

echo "Download completed for event: $EVENT_ID"
