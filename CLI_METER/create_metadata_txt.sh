#!/bin/bash

#################################
# this file creates metadata
# for meter event files in txt
#################################

file=$1
checksum=$2  # Accept checksum as an argument
EVENT_DIR=$3

filename=$(basename "$file")
metadata_file="${EVENT_ID}_metadata.txt"
metadata_path="$EVENT_DIR/$metadata_file"

log "Initiating metadata creation for file: $filename in TXT format"

# Attempt to write metadata, checking for success
if { 
    echo "File: $filename"
    echo "DownloadedAt: $OTDEV_TIMESTAMP"
    echo "MeterEventDate: $METER_TIMESTAMP"
    echo "MeterID: $FTP_METER_ID"
    echo "EventID: $EVENT_ID"
    echo "DataLevel: Level0"
    echo "Checksum: $checksum"  # Include the checksum in the metadata
    echo "----"
} >> "$metadata_path"; then
    log "Successfully created/written metadata for $filename."
    exit 0  # Exit with success code
else
    log "Failed to write metadata for $filename." "err"
    exit 1  # Exit with error code if writing to file fails
fi