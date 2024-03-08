#!/bin/bash

#################################
# This file creates metadata
# for meter event files in TXT
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
metadata_file="${EVENT_ID}_metadata.txt"
metadata_path="$EVENT_DIR/$metadata_file"

log "Initiating metadata (TXT) creation for file: $filename"

# Attempt to write metadata, checking for success
if { 
    echo "File: $filename"
    echo "DownloadedAt: $OTDEV_TIMESTAMP"
    echo "MeterEventDate: $METER_TIMESTAMP"
    echo "MeterID: $METER_ID"
    echo "EventID: $EVENT_ID"
    echo "DataLevel: level0"
    echo "Checksum: $checksum"  # Include the checksum in the metadata
    echo "----"
} >> "$metadata_path"; then
    log "Metadata (TXT) file updated successfully for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata (TXT) for file: $filename" "err"
    return 1  # Exit with error code
fi