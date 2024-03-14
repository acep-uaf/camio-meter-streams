#!/bin/bash

##########################################################
# This file creates metadata
# for meter event files in YAML
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
metadata_file="${event_id}_metadata.yml"
metadata_path="$event_dir/$metadata_file"

log "File: $file"
log "Event directory: $event_dir"
log "Filename: $filename"
log "Metadata file: $metadata_file"
log "Metadata path: $metadata_path"

log "Initiating metadata (YAML) creation for file: $filename"

# Append metadata to the YAML file
if {
    echo "- File: $filename"
    echo "  DownloadedAt: \"$otdev_timestamp\""
    echo "  MeterEventDate: \"$meter_timestamp\""
    echo "  MeterID: \"$METER_ID\""
    echo "  MeterType: \"$METER_TYPE\"" 
    echo "  EventID: \"$event_id\""
    echo "  DataLevel: \"level0\""
} >> "$metadata_path"; then
    log "Metadata (YAML) file updated successfully for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata (YAML) for file: $filename" "err"
    return 1  # Exit with error code
fi
