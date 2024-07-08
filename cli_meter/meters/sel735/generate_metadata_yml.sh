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
# Requirements:       common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check if the correct number of arguments are passed
[ "$#" -ne 6 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <event_id> <event_dir> <meter_id> <meter_type> <event_timestamp> <download_timestamp>"

event_id=$1
event_dir="$2/$event_id" # Assumes location/data_type/working/YYYY-MM/meter_id/event_id
meter_id=$3
meter_type=$4
event_timestamp=$5
download_timestamp=$6

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
    echo "$checksum $filename" >> "$event_dir/checksum.md5" && log "Checksum generated and added to checksum.md5 for file: $filename"

    {
        echo "- File: $filename"
        echo "  DownloadedAt: \"$download_timestamp\""
        echo "  MeterEventDate: \"$event_timestamp\""
        echo "  MeterID: \"$meter_id\""
        echo "  MeterType: \"$meter_type\""
        echo "  EventID: \"$event_id\""
        echo "  DataLevel: \"level0\""
        echo "  Checksum: \"$checksum\""
    } >> "$metadata_path" && log "Metadata generated for: $filename" || failure $STREAMS_FILE_CREATION_FAIL "Failed to generate metadata for: $filename"
}

log "Creating metadata for event: $event_id"

for file in "$event_dir"/*; do
    filename=$(basename "$file")
    if [ -s "$file" ]; then
        # Skip if the file is a metadata file
        if [[ "$file" == *_metadata.yml ]]; then
            log "Skipping metadata creation for: $filename"
            continue
        fi
        create_metadata_yml "$file" "$event_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp" || {
            failure $STREAMS_FILE_CREATION_FAIL "Failed to create metadata file for: $filename"
        }
    else
        failure $STREAMS_FILE_NOT_FOUND "File not found or is empty: $file"
    fi
done

