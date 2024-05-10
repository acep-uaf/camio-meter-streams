#!/bin/bash
# ==============================================================================
# Script Name:        create_metadata_yml.sh
# Description:        This script creates metadata for meter event files in YAML
#                     format and appends the file's checksum to a checksum.md5 file.
#
# Usage:              ./create_metadata_yml.sh <file> <event_dir> <meter_id> <meter_type>
#                     <event_timestamp> <download_timestamp>
# Called by:          generate_event_metadata.sh
#
# Arguments:
#   file              The name of the event file
#   event_dir         The full path to the local event directory
#   meter_id          Meter ID
#   meter_type        Meter Type
#   event_timestamp   Original timestamp of the event
#   download_timestamp Timestamp of when the files were downloaded
#
# Requirements:       commons.sh
#
# ==============================================================================

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
    return 0 # Return with success code
else
    log "Error generating metadata for: $filename"
    return 1 # Return with error code 
fi
