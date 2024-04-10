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
    fail "Usage: $0 <file> <event_dir> <meter_id> <meter_type> <event_timestamp> <download_timestamp>"
fi

file=$1
event_dir=$2
meter_id=$3
meter_type=$4
event_timestamp=$5
download_timestamp=$6

# Extract the event ID from the directory name or another source if it is available differently
event_id=$(basename "$event_dir")

filename=$(basename "$file")
metadata_file="${event_id}_metadata.yml"
metadata_path="$event_dir/$metadata_file"

# Calculate the checksum of the file
checksum=$(md5sum "$file" | awk '{print $1}')

# Append the checksum and filename to a checksum.md5 file in the event directory
echo "$checksum $filename" >> "$event_dir/checksum.md5"

# Append metadata to the YAML file
if {
    echo "- File: $filename"
    echo "  DownloadedAt: \"$download_timestamp\""
    echo "  MeterEventDate: \"$event_timestamp\""
    echo "  MeterID: \"$meter_id\""
    echo "  MeterType: \"$meter_type\""
    echo "  EventID: \"$event_id\""
    echo "  DataLevel: \"level0\""
    echo "  Checksum: \"$checksum\""
} >> "$metadata_path"; then
    log "Metadata generated for: $filename"
    return 0 # Exit with success code
else
    log "Error generating metadata for: $filename"
    return 1 # Exit with error code
fi
