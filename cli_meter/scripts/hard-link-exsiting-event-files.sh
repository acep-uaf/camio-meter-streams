#!/bin/bash
# ==============================================================================
# Script Name:        hard-link-existing-event-files.sh
#
# Description:        This script creates hard links for existing event files
#                     in DAS for .zip and .message files.
#
# Usage:              ./hard-link-existing-event-files.sh <BASE_DIR>
#                      example BASE_DIR: camio-meter-stream-test-2.0/data/kea/events/level0
#                      pwd /home/agreer5/camio-meter-stream-test-2.0
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

# Constants
BASE_DIR="$1"

# Debug
echo "BASE_DIR is set to: $BASE_DIR"

# Function to parse .message file and extract required values using jq
parse_message_file() {
    local message_file="$1"
    local id=$(jq -r '.id' "$message_file")
    local zip_filename=$(jq -r '.filename' "$message_file")
    local path=$(jq -r '.path' "$message_file")
    local data_type=$(jq -r '.data_type' "$message_file")

    echo "$id" "$zip_filename" "$path" "$data_type"
}

# Function to create a hard link
create_hard_link() {
    local original_file="$1"
    local new_file="$2"

    if [ -f "$original_file" ]; then
        if cp -l "$original_file" "$new_file"; then
            echo "Created hard link: $new_file"
        else                         
            echo "FAILED to create hard link: $new_file"
        fi
    else
        echo "Original file not found: $original_file"
    fi
}

#______________________________________________________________________
# Main logic to loop through directories and create hard links
for date_dir in "$BASE_DIR"/*; do
    if [ -d "$date_dir" ]; then
        date=$(basename "$date_dir")

        for meter_dir in "$date_dir"/*; do
            if [ -d "$meter_dir" ]; then
                meter=$(basename "$meter_dir")

                for message_file in "$meter_dir"/*.message; do
                    if [ -f "$message_file" ]; then
                        read id zip_filename path data_type <<< $(parse_message_file "$message_file")

                        # Parse location from path (first path) Ex: kea/path/to
                        location=$(echo "$path" | cut -d'/' -f1)

                        new_file_name="${location}-${data_type}-${meter}-${date}-${zip_filename}"
                        new_message_file_name="${location}-${data_type}-${meter}-${date}-${zip_filename}.message"

                        cur_meter_dir="$BASE_DIR/$date/$meter"
                        original_zip_file_path="$cur_meter_dir/$zip_filename"
                        original_message_file_path="$message_file"

                        new_zip_file_path="$cur_meter_dir/$new_file_name"
                        new_message_file_path="$cur_meter_dir/$new_message_file_name"

                        # Create hard link for the .zip file
                        create_hard_link "$original_zip_file_path" "$new_zip_file_path"

                        # Create hard link for the .message file
                        create_hard_link "$original_message_file_path" "$new_message_file_path"
                    fi
                done
            fi
        done
    fi     
done

echo "END"        