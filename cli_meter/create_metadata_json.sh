#!/bin/bash

#################################
# This file creates metadata
# for meter event files in JSON
#################################
# This script is called from organize_data.sh & download_missing_file.sh and accepts three arguments:
# 1. The name of the file
# 2. The checksum of the file
# 3. The full path to the local event directory
#################################

file=$1
checksum=$2 
EVENT_DIR=$3

filename=$(basename "$file")
metadata_file="${EVENT_ID}_metadata.json"
metadata_path="$EVENT_DIR/$metadata_file"

log "Initiating metadata (JSON) for file: $filename"

# Check if the metadata JSON file already exists, if not, create an empty array
if [ ! -f "$metadata_path" ]; then
    echo '[]' > "$metadata_path"
    log "Created new metadata (JSON) file: $metadata_file"
else
    log "Appending new entry to metadata (JSON) file: $metadata_file"
fi

# Append the new entry with jq and update the metadata file without logging sensitive information
if jq --arg file "$filename" \
    --arg downloadedAt "$OTDEV_TIMESTAMP" \
    --arg meterEventDate "$METER_TIMESTAMP" \
    --arg meterID "$METER_ID" \
    --arg eventID "$EVENT_ID" \
    --arg dataLevel "level0" \
    --arg checksum "$checksum" \
    '. += [{
        File: $file,
        DownloadedAt: $downloadedAt,
        MeterEventDate: $meterEventDate,
        MeterID: $meterID,
        EventID: $eventID,
        DataLevel: $dataLevel,
        Checksum: $checksum
    }]' "$metadata_path" > "tmp.$$.json" && mv "tmp.$$.json" "$metadata_path"; then
    log "Metadata (JSON) file updated successfully for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata (JSON) for file: $filename" "err"
    return 1  # Exit with error code
fi
