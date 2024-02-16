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
# Full path for CHISTORY.txt
FULL_PATH=$LOCAL_PATH/$REMOTE_TARGET_FILE

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
if [ -f "$FULL_PATH" ] && [ -s "$FULL_PATH"]; then
    log "$FULL_PATH downloaded successfully, starting to parse data..."

    # Parse each line to get event ID and then extract timestamp components from the line
    while IFS= read -r line; do
        # Extract event ID using awk, assuming it's the second field in the line
        event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

        log "Event ID $event_id"
        # Check if $event_id is entirely numeric
        if [[ $event_id =~ ^[0-9]+$ ]]; then
            # Extract timestamp components from the line
            read month day year hour min sec msec <<<$(echo "$line" | awk -F, '{print $3, $4, $5, $6, $7, $8, $9}')

            # Format timestamp into ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sss
            METER_TIMESTAMP=$(printf '%04d-%02d-%02dT%02d:%02d:%02d.%03d' $year $month $day $hour $min $sec $msec)

            if [ -d "$LOCAL_PATH/$FTP_METER_ID/level0/$event_id" ]; then
                log "Directory exists for most recent event: $event_id. Event files up to date. update_event_files.sh exit 0"
                echo "Nothing to download, you're all up to date."
                exit 0
            else
                chmod +x download_by_id.sh
                log "Calling download for event: $event_id"
                source download_by_id.sh "$FTP_METER_SERVER_IP" "$event_id"
                OTDEV_TIMESTAMP=$(date --iso-8601=seconds)
                log "Download date from meter to ot-dev: $OTDEV_TIMESTAMP"
                # Create metadata and checksums, passing both event_id and timestamp
                source organize_data.sh "$event_id" "$METER_TIMESTAMP" "$OTDEV_TIMESTAMP"
            fi
        fi
    done < <(awk 'NR > 3' "$LOCAL_PATH/$REMOTE_TARGET_FILE")
else
    log "Failed to download $REMOTE_TARGET_FILE from FTP server."
fi


log "update_event_files.sh completed"
