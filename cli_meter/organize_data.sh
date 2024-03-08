#!/bin/bash

#################################
# This script:
# - creates metadata & checksums/md5sum
# - is called from update_event_files.sh
# - uses environment variables
# - accepts 3 arguments: event_id, meter_timestamp, otdev_timestamp
# - calls create_metadata_txt.sh and create_metadata_json.sh
#################################

EVENT_ID=$1
METER_TIMESTAMP=$2
OTDEV_TIMESTAMP=$3

# Format the log entry
log_entry=$(printf "%-20s | %-30s | %-30s" "$EVENT_ID" "$METER_TIMESTAMP" "$OTDEV_TIMESTAMP")
log "Organize Data: $log_entry"

# Base directory where the event files are located
EVENT_DIR="$DATA_TYPE/$METER_ID/level0/$EVENT_ID"
log "current event dir: $EVENT_DIR"

# Loop through each file in the event directory
for file in "$EVENT_DIR"/*; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Compute checksum once here
        checksum=$(md5sum "$file" | awk '{ print $1 }')

        # Pass the file and checksum to both metadata creation functions
        source create_metadata_txt.sh "$file" "$checksum" "$EVENT_DIR"
        if [ $? -ne 0 ]; then
            log "create_metadata_txt.sh failed for: $file" "err"
        fi

        # Source and check create_metadata_json.sh
        source create_metadata_json.sh "$file" "$checksum" "$EVENT_DIR"
        if [ $? -ne 0 ]; then
            log "create_metadata_json.sh failed for: $file" "err"
        fi

        # Store the checksum in a separate file with the same name plus .md5 extension
        filename=$(basename "$file")
        echo "$checksum" >"$EVENT_DIR/${filename}.md5"
    else
        log "Skipped: No file found for $file" "warn"
    fi

    log "Metadata and checksums created for: $EVENT_ID"
done
