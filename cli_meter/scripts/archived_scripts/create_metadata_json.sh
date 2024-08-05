#!/bin/bash

##########################################################
# This file creates metadata
# for meter event files in JSON
#
# This script is called from organize_data.sh & 
# download_missing_file.sh and accepts 2 arguments:
# 1. The name of the file
# 2. The full path to the local event directory
##########################################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <file> <event_dir>"
    exit 1
fi

file=$1
event_dir=$2

filename=$(basename "$file")
metadata_file="${event_id}_metadata.json"
metadata_path="$event_dir/$metadata_file"

log "File: $file"
log "Event directory: $event_dir"
log "Filename: $filename"
log "Metadata file: $metadata_file"

log "Initiating metadata (JSON) for filename: $filename"

# Check if the metadata JSON file already exists, if not, create an empty array
if [ ! -f "$metadata_path" ]; then
    echo '[]' > "$metadata_path"
    log "Created new metadata (JSON) file: $metadata_file"
else
    log "Appending new entry to metadata (JSON) file: $metadata_file"
fi

# Append the new entry with jq and update the metadata file without logging sensitive information
if jq --arg file "$filename" \
    --arg downloadedAt "$otdev_timestamp" \
    --arg meterEventDate "$meter_timestamp" \
    --arg meterID "$METER_ID" \
    --arg eventID "$event_id" \
    --arg dataLevel "level0" \
    '. += [{
        File: $file,
        DownloadedAt: $downloadedAt,
        MeterEventDate: $meterEventDate,
        MeterID: $meterID,
        EventID: $eventID,
        DataLevel: $dataLevel,
    }]' "$metadata_path" > "tmp.$$.json" && mv "tmp.$$.json" "$metadata_path"; then
    log "Metadata (JSON) file updated successfully for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata (JSON) for file: $filename" "err"
    return 1  # Exit with error code
fi
