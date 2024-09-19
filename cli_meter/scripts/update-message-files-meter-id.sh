#!/bin/bash
# ==============================================================================
# Script Name:        update-message-files-meter-id.sh
#
# Description:        This script processes message files to add a "meter_id"
#                     field to the JSON structure of the .message files.
#
# Usage:              ./update-message-files-meter-id.sh <BASE_DIR>
#
# Arguments:          BASE_DIR - The base directory to process
#
# Requirements:       jq
#
# ==============================================================================

# Check if BASE_DIR is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <BASE_DIR>"
    exit 1
fi

BASE_DIR="$1"

updated_count=0
skipped_count=0

# Function to update the message file format to include meter_id
add_meter_id_to_message_file() {
    local message_file="$1"
    local meter_id="$2"

    # Check if the message file is already in V4 format (contains meter_id)
    if jq -e '.meter_id' "$message_file" > /dev/null 2>&1; then
        skipped_count=$((skipped_count + 1))
        return
    fi

    # Extract current values from the message file
    local event_id=$(jq -r '.event_id' "$message_file")
    local filename=$(jq -r '.filename' "$message_file")
    local md5sum=$(jq -r '.md5sum' "$message_file")
    local data_type=$(jq -r '.data_type' "$message_file")

    # Update the message file by adding "meter_id"
    jq --arg meter_id "$meter_id" '. | {event_id: .event_id, meter_id: $meter_id, filename: .filename, md5sum: .md5sum, data_type: .data_type}' "$message_file" > "$message_file.tmp" && mv "$message_file.tmp" "$message_file"
    echo "Updated: $(basename "$message_file")"
    updated_count=$((updated_count + 1))
}

# Main script logic to process directories and files
for date_dir in "$BASE_DIR"/*; do
    if [ -d "$date_dir" ]; then
        cur_date_dir=$(basename "$date_dir")
        echo "Processing date directory: $cur_date_dir"

        for meter_dir in "$date_dir"/*; do
            if [ -d "$meter_dir" ]; then
                meter_id=$(basename "$meter_dir")
                echo "Processing meter directory: $meter_id"

                for message_file in "$meter_dir"/*.message; do
                    if [ -f "$message_file" ]; then
                        add_meter_id_to_message_file "$message_file" "$meter_id"
                    fi
                done
            fi
        done
    fi     
done

# Print the tally of updated and skipped files
echo -e "\nFinished processing message files in: $BASE_DIR\n"
echo "Summary of Processed Message Formats:"
echo "Files updated from V3 to V4 format (added 'meter_id'): $updated_count"
echo "Files already in V4 format (skipped): $skipped_count"

# If no files were processed
if [ "$updated_count" -eq 0 ] && [ "$skipped_count" -eq 0 ]; then
    echo "No message files were found or processed."
fi