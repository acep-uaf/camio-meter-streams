#!/bin/bash
# ==============================================================================
# Script Name:        cleanup-v1-event-files.sh
#
# Description:        This script deletes old event files (both .zip and .message)
#                     in Version 1 format, but only if the corresponding
#                     Version 3 file exists.
#
# V1:                 event_id.zip and event_id.zip.message
# V3:                 New format with the md5sum in the message file
#
# Usage:              ./cleanup-v1-event-files.sh <BASE_DIR>
#
# Arguments:          BASE_DIR - The base directory to remove files from
#
# ==============================================================================

# Check if BASE_DIR is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <BASE_DIR>"
    exit 1
fi

BASE_DIR="$1"

# Check if the directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory $BASE_DIR does not exist."
    exit 1
else
    echo "Removing old event files from: $BASE_DIR"
fi

check_v3_exists() {
    local event_id="$1"
    local meter_dir="$2"

    # Find any Version 3 files with the corresponding event_id in the meter directory
    v3_message_file=$(find "$meter_dir" -type f -name "*-$event_id.zip.message" -print -quit)

    if [[ -n "$v3_message_file" ]]; then
        if grep -q '"md5sum"' "$v3_message_file"; then
            return 0  # Version 3 file exists
        fi
    fi
    
    echo "No corresponding Version 3 file found for event_id: $event_id"
    return 1  # Version 3 file does not exist
}

# Function to delete the old event files
delete_old_files() {
    local zip_file="$1"
    local message_file="$2"
    
    # Delete both .zip and .message files
    if rm "$zip_file" "$message_file"; then
        echo "Deleted: $zip_file and $message_file"
    else
        echo "Error: Failed to delete $zip_file and/or $message_file"
    fi
}

# Main loop: find all .zip files in the base directory
find "$BASE_DIR" -type f -name "*.zip" | while read -r zip_file; do
    message_file="${zip_file}.message"

    # Check for Version 1
    if [[ "$zip_file" =~ ^.*/[0-9]+\.zip$ ]]; then
        event_id=$(basename "$zip_file" .zip)
        meter_dir=$(dirname "$zip_file")

        if check_v3_exists "$event_id" "$meter_dir"; then
            delete_old_files "$zip_file" "$message_file"
        else
            echo "Skipping deletion for $zip_file as no Version 3 file exists."
        fi
    fi
done

echo "Cleanup completed."