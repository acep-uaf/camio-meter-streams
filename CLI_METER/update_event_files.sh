#!/bin/bash

# update_event_files.sh

# Function to log messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

REMOTE_TARGET_FILE="CHISTORY.TXT"
LOG_FILE="log_update_event_files.log"

log "Checking for updates..."

# Create local directory if it doesn't exist
if mkdir -p "$LOCAL_PATH"; then
    log "Local directory: $LOCAL_PATH exists."
else
    log "Error: Failed to create local directory $LOCAL_PATH."
fi

# Start lftp session to download the file
lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$FTP_METER_SERVER_IP" <<EOF
set xfer:clobber on
cd $FTP_REMOTE_METER_PATH
lcd $LOCAL_PATH
mget $REMOTE_TARGET_FILE
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session completed successfully."
else
    log "lftp session encountered an error."
fi

# Check if the CHISTORY.TXT file was successfully downloaded
if [ -f "$LOCAL_PATH/$REMOTE_TARGET_FILE" ]; then
    log "$REMOTE_TARGET_FILE downloaded successfully, starting to parse data..."

    # Parse and check for matching directory based on the second column
    while IFS= read -r event_id; do
    # Check if $event_id is entirely numeric
    if [[ $event_id =~ ^[0-9]+$ ]]; then  
        if [ -d "$LOCAL_PATH/$FTP_METER_ID/level0/$event_id" ]; then
            log "Directory exits for most recent event: $event_id. Event files up to date. update_event_files.sh exit 0"
            echo "Nothing to download, you're all up to date."
            exit 0
        else
            chmod +x download_by_id.sh
            log "Calling download for event: $event_id"
            source download_by_id.sh "$FTP_METER_SERVER_IP" "$event_id"
        fi
    fi
    done < <(awk -F, 'NR > 3 { gsub(/"/, "", $2); print $2 }' "$LOCAL_PATH/$REMOTE_TARGET_FILE")


else
    log "Failed to download $REMOTE_TARGET_FILE from FTP server."
fi

log "update_event_files.sh completed"
