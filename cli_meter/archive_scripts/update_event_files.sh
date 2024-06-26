#!/bin/bash

#################################
# This script:
# - checks for new events and missing files
# - is called from data_pipeline.sh
# - uses environment variables
#################################

# Source the common functions and variables
otdev_timestamp=$(date --iso-8601=seconds)
REMOTE_TARGET_FILE="CHISTORY.TXT"
FILES_PER_EVENT=12

download_event() {
    event_id=$1
    METER_TIMESTAMP=$2
    log "Calling download for event: $event_id"

    # Call the download_by_id script to download the event files
    source download_by_id.sh "$METER_IP" "$event_id"

    # Create metadata and checksums, passing both event_id and timestamp
    source generate_event_metadata.sh "$event_id" "$METER_TIMESTAMP" "$otdev_timestamp"
}

log "Checking for new events and missing files..."
echo "Checking for new events and missing files..."

# Create local directory if it doesn't exist
if mkdir -p "$DATA_TYPE"; then
    log "Created/verified local directory: $DATA_TYPE"
else
    log "Failed to create local directory: $DATA_TYPE" "err"
fi

# Full path for CHISTORY.txt
FULL_PATH=$DATA_TYPE/$REMOTE_TARGET_FILE

# Start lftp session to download the file
lftp -u "$USERNAME,$PASSWORD" "$METER_IP" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $DATA_TYPE
mget $REMOTE_TARGET_FILE
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session successful"
else
    log "lftp session failed" "err"
fi

# Check if the CHISTORY.TXT file was successfully downloaded
if [ -f "$FULL_PATH" ] && [ -s "$FULL_PATH" ]; then
    log "Parsing downloaded data from $FULL_PATH..."

    # Parse each line to get event ID and then extract timestamp components from the line
    while IFS= read -r line; do
        # Extract event ID using awk, assuming it's the second field in the line
        event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

        # Check if $event_id is entirely numeric
        if [[ $event_id =~ ^[0-9]+$ ]]; then
            FULL_PATH_EVENT_DIR="$DATA_TYPE/$METER_ID/level0/$event_id"

            # Extract timestamp components from the line
            read month day year hour min sec msec <<<$(echo "$line" | awk -F, '{print $3, $4, $5, $6, $7, $8, $9}')

            # Format timestamp into ISO 8601 format: YYYY-MM-DDTHH:MM:SS.sss
            METER_TIMESTAMP=$(printf '%04d-%02d-%02dT%02d:%02d:%02d.%03d' $year $month $day $hour $min $sec $msec)

            if [ -d "$FULL_PATH_EVENT_DIR" ]; then
                log "Checking event directory: $event_id"
                
                # Count the number of non-empty files in the directory
                non_empty_files_count=$(find "$FULL_PATH_EVENT_DIR" -type f ! -empty -print | wc -l)

                # Check if the directory is complete or incomplete
                if [ "$non_empty_files_count" -eq 12 ]; then
                    log "Complete directory for event: $event_id"

                elif [ "$non_empty_files_count" -ne 0 ]; then
                    log "Incomplete event: $event_id" "warn"
                    source download_missing_file.sh "$FULL_PATH_EVENT_DIR" "$event_id"
                fi
                
            else #dir doesn't exists for most recent event download all events for event_id 
                download_event "$event_id" "$METER_TIMESTAMP"
            fi
        else
            log "Skipping line: $line, not entirely numeric" "warn"
        fi
    done < <(awk 'NR > 3' "$DATA_TYPE/$REMOTE_TARGET_FILE")
    log "Completed processing all events listed in $REMOTE_TARGET_FILE."
else
    log "Download failed: $REMOTE_TARGET_FILE" "err"
fi

echo "Finished downloading and updating events successfully."


