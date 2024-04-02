#!/bin/bash

##############################################################
# This script:
# - creates metadata 
# - is called from download.sh
# - uses environment variables
# - accepts 2 arguments: event_id and event_dir
# - calls create_metadata_txt.sh and create_metadata_json.sh
###############################################################

log "Creating metadata for event: $event_id"

# Check if the correct number of arguments are passed
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <event_id> <event_dir> <meter_id> <meter_type> <meter_download_timestamp> <otdev_download_timestamp>"
    exit 1
fi


event_id=$1
event_dir="$2/$event_id" # Assumes LOCATION/DATA_TYPE/YYYY-MM/METER_ID/
meter_id=$3
meter_type=$4
meter_download_timestamp=$5
otdev_download_timestamp=$6


# Directory where this script is located (not the same as pwd because data_pipeline.sh is in another dir)
current_dir=$(dirname "${0}")

# Loop through each file in the event directory
for file in "$event_dir"/*; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Source and check create_metadata_yml.sh
        source "$current_dir/create_metadata_yml.sh" "$file" "$event_dir" "$meter_id" "$meter_type" "$meter_download_timestamp" "$otdev_download_timestamp"
        if [ $? -ne 0 ]; then
            log "create_metadata_yml.sh failed for: $file" "err"
        fi

    else
        log "Skipped: No file found for $file" "warn"
    fi
done

log "Metadata generated for event: $event_id"
