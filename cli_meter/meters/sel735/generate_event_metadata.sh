#!/bin/bash

##############################################################
# This script:
# - creates metadata 
# - is called from download.sh
# - uses environment variables
# - accepts 2 arguments: event_id and event_dir
# - calls create_metadata_txt.sh and create_metadata_json.sh
###############################################################

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

        # Source and check create_metadata_yml.sh
        source create_metadata_yml.sh "$file" "$event_dir"
        if [ $? -ne 0 ]; then
            log "create_metadata_yml.sh failed for: $file" "err"
        fi

    else
        log "Skipped: No file found for $file" "warn"
    fi

    log "Metadata created for: $event_id"
done
