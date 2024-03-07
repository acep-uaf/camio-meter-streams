#!/bin/bash

# After downloading is complete and up to data 
# this file does the following: 
# 1. creates metadata 
# 2. checksum/md5sum
######################################################

EVENT_ID=$1
METER_TIMESTAMP=$2
OTDEV_TIMESTAMP=$3 

# Format the log entry
log_entry=$(printf "%-20s | %-30s | %-30s" "$EVENT_ID" "$METER_TIMESTAMP" "$OTDEV_TIMESTAMP")
log "Organize Data: $log_entry"

# Base directory where the event files are located
EVENT_DIR="$LOCAL_PATH/$FTP_METER_ID/level0/$EVENT_ID"
log "current event dir: $EVENT_DIR"

# Loop through each file in the event directory
for file in "$EVENT_DIR"/*; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Compute checksum once here
        checksum=$(md5sum "$file" | awk '{ print $1 }')

        # Pass the file and checksum to both metadata creation functions
        source create_metadata_txt.sh "$file" "$checksum" "$EVENT_DIR"
        if [ $? -ne 0 ]; then
            log "create_metadata_txt.sh failed" "err"
        fi
        
        # Source and check create_metadata_json.sh
        source create_metadata_json.sh "$file" "$checksum" "$EVENT_DIR"
        if [ $? -ne 0 ]; then
            log "create_metadata_json.sh failed" "err"
        fi

        # Store the checksum in a separate file with the same name plus .md5 extension
        filename=$(basename "$file")
        echo "$checksum" > "$EVENT_DIR/${filename}.md5"
    else
        log "Skipped: No file found for $file" "warn"
    fi
done

log "Metadata and checksums created for files in $EVENT_DIR."

