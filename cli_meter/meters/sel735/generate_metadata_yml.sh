#!/bin/bash
# ==============================================================================
# Script Name:        generate_and_create_metadata.sh
# Description:        This script creates metadata for the specified event files
#                     using environment variables and outputs it in YML format.
#
# Usage:              ./generate_and_create_metadata.sh <event_id> <event_dir> <meter_id>
#                     <meter_type> <event_timestamp> <download_timestamp>
#
# Arguments:
#   event_id          Event ID
#   event_dir         Directory where the event files are stored
#   meter_id          Meter ID
#   meter_type        Meter type
#   event_timestamp   Original timestamp of the event
#   download_timestamp Timestamp of when the files were downloaded
#
# Requirements:       commons.sh
# ==============================================================================

log "Creating metadata for event: $event_id"

# Check if the correct number of arguments are passed
[ "$#" -ne 6 ] && fail "Usage: $0 <event_id> <event_dir> <meter_id> <meter_type> <event_timestamp> <download_timestamp>"

event_id=$1
event_dir="$2/$event_id" # Assumes location/data_type/working/YYYY-MM/meter_id/event_id
meter_id=$3
meter_type=$4
event_timestamp=$5
download_timestamp=$6

# Directory where this script is located
current_dir=$(dirname "${0}")

# Function to create metadata in YML format and append the file's checksum
create_metadata_yml() {
    file=$1
    event_dir=$2
    meter_id=$3
    meter_type=$4
    event_timestamp=$5
    download_timestamp=$6

    event_id=$(basename "$event_dir")
    filename=$(basename "$file")
    metadata_file="${event_id}_metadata.yml"
    metadata_path="$event_dir/$metadata_file"

    checksum=$(md5sum "$file" | awk '{print $1}')
    echo "$checksum $filename" >> "$event_dir/checksum.md5"

    {
        echo "- File: $filename"
        echo "  DownloadedAt: \"$download_timestamp\""
        echo "  MeterEventDate: \"$event_timestamp\""
        echo "  MeterID: \"$meter_id\""
        echo "  MeterType: \"$meter_type\""
        echo "  EventID: \"$event_id\""
        echo "  DataLevel: \"level0\""
        echo "  Checksum: \"$checksum\""
    } >> "$metadata_path" && log "Metadata generated for: $filename" || fail "Failed to generate metadata for: $filename"
}

# Loop through each file in the event directory
for file in "$event_dir"/*; do
    [ -f "$file" ] && [ -s "$file" ] && {
        log "Processing file: $file"
        create_metadata_yml "$file" "$event_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp" || fail "Failed to create metadata file for: $file"
    } || {
        fail "File not found or is empty: $file"
    }
done
