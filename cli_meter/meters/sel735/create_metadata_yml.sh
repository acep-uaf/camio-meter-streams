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
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <file> <event_dir> <meter_id> <meter_type> <meter_download_timestamp> <otdev_download_timestamp>"
    exit 1
fi

file=$1
event_dir=$2
meter_id=$3
meter_type=$4
meter_download_timestamp=$5
otdev_download_timestamp=$6


filename=$(basename "$file")
metadata_file="${event_id}_metadata.yml"
metadata_path="$event_dir/$metadata_file"


log "Starting metadata generation for file: $filename"

# Append metadata to the YAML file
if {
    echo "- File: $filename"
    echo "  DownloadedAt: \"$otdev_download_timestamp\""
    echo "  MeterEventDate: \"$meter_download_timestamp\""
    echo "  MeterID: \"$meter_id\""
    echo "  MeterType: \"$meter_type\"" 
    echo "  EventID: \"$event_id\""
    echo "  DataLevel: \"level0\""
} >> "$metadata_path"; then
    log "Metadata updated for: $filename"
    return 0  # Exit with success code
else
    log "Error updating metadata for file: $filename" "err"
    return 1  # Exit with error code
fi
