#!/bin/bash

#################################
# This file creates metadata
# for meter event files in JSON
#################################

file=$1
checksum=$2  # Accept checksum as an argument
EVENT_DIR=$3

filename=$(basename "$file")
metadata_file="${EVENT_ID}_metadata.json"
metadata_path="$EVENT_DIR/$metadata_file"

log "Initiating metadata creation for file: $filename in JSON format"

# Check if the metadata JSON file already exists, if not, create an empty array
if [ ! -f "$metadata_path" ]; then
    echo '[]' > "$metadata_path"
    log "Created new metadata file: $metadata_file"
else
    log "Appending new entry to existing metadata file: $metadata_file"
fi

# Append the new entry with jq and update the metadata file without logging sensitive information
if jq --arg file "$filename" \
    --arg downloadedAt "$OTDEV_TIMESTAMP" \
    --arg meterEventDate "$METER_TIMESTAMP" \
    --arg meterID "$FTP_METER_ID" \
    --arg eventID "$EVENT_ID" \
    --arg dataLevel "Level0" \
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
    log "Metadata file updated successfully for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata for file: $filename" "err"
    return 1  # Exit with error code
fi
