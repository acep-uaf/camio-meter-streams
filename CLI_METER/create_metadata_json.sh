#!/bin/bash

#################################
# this file creates metadata
# for meter event files in JSON
#################################

file=$1
checksum=$2  # Accept checksum as an argument
EVENT_DIR=$3

filename=$(basename "$file")
metadata_file="$EVENT_DIR/${EVENT_ID}_metadata.json"

log "file in create-meta $file"
# Check if the metadata JSON file already exists, if not create an empty array
if [ ! -f "$metadata_file" ]; then
    echo '[]' > "$metadata_file"
fi

# Read the existing JSON data, add the new entry with the checksum, and write back to the file
jq --arg file "$filename" \
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
    }]' "$metadata_file" > "tmp.$$.json" && mv "tmp.$$.json" "$metadata_file"
