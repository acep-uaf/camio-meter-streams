#!/bin/bash

#################################
# This script:
# - creates metadata & checksums/md5sum
# - is called from download.sh
# - uses environment variables
# - accepts 2 arguments: event_id and event_dir
# - calls create_metadata_txt.sh and create_metadata_json.sh
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <event_id> <event_dir>"
    exit 1
fi

event_id=$1
event_dir="$2/level0/$event_id" # Assumes LOCATION/DATA_TYPE/YYYY-MM/METER_ID/
meter_timestamp=$(date --iso-8601=seconds) # CHANGE: This is not the timestamp from the meter
otdev_timestamp=$(date --iso-8601=seconds)

# Loop through each file in the event directory
for file in "$event_dir"/*; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Compute checksum once here
        checksum=$(md5sum "$file" | awk '{ print $1 }')

        # Pass the file and checksum to both metadata creation functions
        source create_metadata_txt.sh "$file" "$checksum" "$event_dir"
        if [ $? -ne 0 ]; then
            log "create_metadata_txt.sh failed for: $file" "err"
        fi

        # Source and check create_metadata_json.sh
        source create_metadata_json.sh "$file" "$checksum" "$event_dir"
        if [ $? -ne 0 ]; then
            log "create_metadata_json.sh failed for: $file" "err"
        fi

        # Store the checksum in a separate file with the same name plus .md5 extension
        filename=$(basename "$file")
        echo "$checksum" >"$event_dir/${filename}.md5"
    else
        log "Skipped: No file found for $file" "warn"
    fi

    log "Metadata and checksums created for: $event_id"
done
