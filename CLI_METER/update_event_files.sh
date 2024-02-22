#!/bin/bash

download_event() {
    event_id=$1
    METER_TIMESTAMP=$2
    log "Calling download for event: $event_id" "INFO" "$LOG_FILE"
    source download_by_id.sh "$FTP_METER_SERVER_IP" "$event_id"
    ## write to JSON event id and OTDEV_TIMESTAMP to create file to show all downloads 
    ## save in $LOCAL_PATH
    OTDEV_TIMESTAMP=$(date --iso-8601=seconds)
    log "Download date from meter to ot-dev: $OTDEV_TIMESTAMP" "INFO" "$LOG_FILE"
    # Create metadata and checksums, passing both event_id and timestamp
    source organize_data.sh "$event_id" "$METER_TIMESTAMP" "$OTDEV_TIMESTAMP"
}

REMOTE_TARGET_FILE="CHISTORY.TXT"
LOG_FILE="$LOG_DIR/update_event_files.log"
FILES_PER_EVENT=12

log "Checking for new events and missing files..." "INFO" "$LOG_FILE"
echo "Checking for new events and missing files..."

# Create local directory if it doesn't exist
if mkdir -p "$LOCAL_PATH"; then
    log "Local directory: $LOCAL_PATH exists." "INFO" "$LOG_FILE"
else
    log "Error: Failed to create local directory $LOCAL_PATH." "ERROR" "$LOG_FILE"
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
    log "lftp session completed successfully." "SUCCESS" "$LOG_FILE"
else
    log "lftp session encountered an error." "ERROR" "$LOG_FILE"
fi

# Check if the CHISTORY.TXT file was successfully downloaded
if [ -f "$FULL_PATH" ] && [ -s "$FULL_PATH" ]; then
    log "$FULL_PATH downloaded successfully, starting to parse data..." "INFO" "$LOG_FILE"

    # Parse each line to get event ID and then extract timestamp components from the line
    while IFS= read -r line; do
        # Extract event ID using awk, assuming it's the second field in the line
        event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

        log "Event ID $event_id" "INFO" "$LOG_FILE"
        # Check if $event_id is entirely numeric
        if [[ $event_id =~ ^[0-9]+$ ]]; then
            FULL_PATH_EVENT_DIR="$LOCAL_PATH/$FTP_METER_ID/level0/$event_id"

            # Extract timestamp components from the line
            read month day year hour min sec msec <<<$(echo "$line" | awk -F, '{print $3, $4, $5, $6, $7, $8, $9}')

            # Format timestamp into ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sss
            METER_TIMESTAMP=$(printf '%04d-%02d-%02dT%02d:%02d:%02d.%03d' $year $month $day $hour $min $sec $msec)

            if [ -d "$FULL_PATH_EVENT_DIR" ]; then
                log "Directory exists for most recent event: $event_id." "INFO" "$LOG_FILE"
                
                # Count the number of non-empty files in the directory
                non_empty_files_count=$(find "$FULL_PATH_EVENT_DIR" -type f ! -empty -print | wc -l)

                if [ "$non_empty_files_count" -eq 12 ]; then
                    log "All files are present for event: $event_id." "INFO" "$LOG_FILE"

                elif [ "$non_empty_files_count" -ne 0 ]; then
                    log "Some files are missing for event: $event_id" "INFO" "$LOG_FILE"
                    log "Call download_missing_file.sh" "INFO" "$LOG_FILE"
                    source download_missing_file.sh "$FULL_PATH_EVENT_DIR" "$event_id"
                fi
                
            else #dir doesn't exists for most recent event download all events for event_id 
                download_event "$event_id" "$METER_TIMESTAMP"
            fi
        fi
    done < <(awk 'NR > 3' "$LOCAL_PATH/$REMOTE_TARGET_FILE")
else
    log "Failed to download $REMOTE_TARGET_FILE from FTP server." "ERROR" "$LOG_FILE"
fi


log "update_event_files.sh completed" "SUCESS" "$LOG_FILE"
echo "Event file update completed successfully."

