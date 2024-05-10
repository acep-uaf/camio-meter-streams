#!/bin/bash
# ==============================================================================
# Script Name:        generate_event_metadata.sh
# Description:        This script creates metadata for the specified event files
#                     using environment variables and calls create_metadata_yml to 
#                     output it in YML format.
#
# Usage:              ./generate_event_metadata.sh <event_id> <event_dir> <meter_id>
#                     <meter_type> <event_timestamp> <download_timestamp>
# Called by:          download.sh
#
# Arguments:
#   event_id          Event ID
#   event_dir         Directory where the event files are stored
#   meter_id          Meter ID
#   meter_type        Meter type
#   event_timestamp   Original timestamp of the event
#   download_timestamp Timestamp of when the files were downloaded
#
# Requirements:       create_metadata_yml.sh
# ==============================================================================

log "Creating metadata for event: $event_id"

# Check if the correct number of arguments are passed
if [ "$#" -ne 6 ]; then
    fail "Usage: $0 <event_id> <event_dir> <meter_id> <meter_type> <event_timestamp> <download_timestamp>"
fi

event_id=$1
event_dir="$2/$event_id" # Assumes location/data_type/working/YYYY-MM/meter_id/event_id
meter_id=$3
meter_type=$4
event_timestamp=$5
download_timestamp=$6

# Directory where this script is located
current_dir=$(dirname "${0}")

# Loop through each file in the event directory
for file in "$event_dir"/*; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        # Source and check create_metadata_yml.sh
        source "$current_dir/create_metadata_yml.sh" "$file" "$event_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp"

        if [ $? -ne 0 ]; then
            fail "create_metadata_yml.sh failed for: $file"
        fi

    else
        fail "No file found for $file"
    fi
done
