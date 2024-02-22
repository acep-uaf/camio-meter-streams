#!/bin/bash

#################################
# this file creates metadata
# for meter event files in txt
#################################

LOG_FILE="create_meta_txt.log"

file=$1
checksum=$2  # Accept checksum as an argument
EVENT_DIR=$3

filename=$(basename "$file")
metadata_file="$EVENT_DIR/${EVENT_ID}_metadata.txt"

log "Creating/Writing to $metadata_file for $file" "INFO" "$LOG_FILE"
{
    echo "File: $filename"
    echo "DownloadedAt: $OTDEV_TIMESTAMP"
    echo "MeterEventDate: $METER_TIMESTAMP"
    echo "MeterID: $FTP_METER_ID"
    echo "EventID: $EVENT_ID"
    echo "DataLevel: Level0"
    echo "Checksum: $checksum"  # Include the checksum in the metadata
    echo "----"
} >> "$metadata_file"