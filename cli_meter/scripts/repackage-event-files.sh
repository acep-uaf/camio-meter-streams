#!/bin/bash
# ==============================================================================
# Script Name:        repackage-event-files.sh
#
# Description:        This script unzips, renames, and re-zips event files
#                     in DAS for .zip and .message files to achieve a new
#                     naming convention. 
#
# Naming Convention:  location-data_type-meter-YYYYMM-id
#                     Ex. kea-events-meter1-202401-12345 
#                     
# Example:            Original zip file: 12345.zip
#                     Original message file: 12345.zip.message
#
#                     New zip file: kea-events-meter1-202401-12345.zip
#                     New message file: kea-events-meter1-202401-12345.zip.message
#
# Usage:              ./repackage-event-files.sh <BASE_DIR>
#                      example BASE_DIR: camio-meter-stream-test/data/kea/events/level0
#                      pwd /home/user/camio-meter-stream-test
#
# Arguments:          BASE_DIR - The base directory to process
#
# Requirements:       jq, unzip, zip
#
# ==============================================================================

# Check if BASE_DIR is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <BASE_DIR>"
    exit 1
fi

# Constants
BASE_DIR="$1"

echo "Updating directory: $BASE_DIR"

# Function to parse .message file and extract required values using jq
parse_message_file() {
    local message_file="$1"
    local id=$(jq -r '.id' "$message_file")
    local zip_filename=$(jq -r '.filename' "$message_file")
    local path=$(jq -r '.path' "$message_file")
    local data_type=$(jq -r '.data_type' "$message_file")

    echo "$id" "$zip_filename" "$path" "$data_type"
}

# Function to unzip, rename the directory, and repackage the zip file
repackage_event_file() {
    local original_zip_file="$1"
    local new_zip_file="$2"
    local new_dir_name="$3"
    
    # Create a temporary directory for unzipping
    temp_dir=$(mktemp -d) || { echo "Failed to create temporary directory"; return 1; }
    
    # Unzip the original file
    unzip -q "$original_zip_file" -d "$temp_dir" && echo "Unzipped: $original_zip_file" || { echo "Failed to unzip: $original_zip_file"; rm -rf "$temp_dir"; return 1; }
    
    # Rename the extracted directory
    original_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d)
    mv "$original_dir" "$temp_dir/$new_dir_name" && echo "Renamed directory to: $new_dir_name" || { echo "Failed to rename directory: $original_dir"; rm -rf "$temp_dir"; return 1; }
    
    # Repackage the contents into a new zip file with the new directory name
    (cd "$temp_dir" && zip -r -q "$new_zip_file" "$new_dir_name") && echo "Repackaged: $new_zip_file" || { echo "Failed to repackage: $new_zip_file"; rm -rf "$temp_dir"; return 1; }
    
    # Remove the temporary directory
    rm -rf "$temp_dir" || { echo "Failed to remove temporary directory: $temp_dir"; return 1; }
}

# Main logic to loop through directories and process files
for date_dir in "$BASE_DIR"/*; do
    if [ -d "$date_dir" ]; then
        echo "Processing date directory: $date_dir"
        cur_date_dir=$(basename "$date_dir")
        # Format date directory to remove hyphens
        fmt_date_dir=$(echo "$cur_date_dir" | sed 's/-//g')

        for meter_dir in "$date_dir"/*; do
            if [ -d "$meter_dir" ]; then
                meter=$(basename "$meter_dir")

                for message_file in "$meter_dir"/*.message; do
                    if [ -f "$message_file" ]; then
                        # Check if the message file matches the new naming convention
                        if [[ "$message_file" =~ ^.*/[^/]+-[^/]+-[^/]+-[0-9]{6}-[0-9]+\.zip\.message$ ]]; then
                            echo "Skipping already repackaged file: $message_file"
                            continue
                        fi

                        # Parse the message file
                        read id zip_filename path data_type <<< $(parse_message_file "$message_file")

                        # Parse location from path (first path) Ex: kea/path/to
                        location=$(echo "$path" | cut -d'/' -f1)

                        # New naming conventions example: kea-events-meter1-202401-12345
                        new_dir_name="${location}-${data_type}-${meter}-${fmt_date_dir}-${id}"
                        new_zip_file_name="${new_dir_name}.zip"
                        new_message_file_name="${new_zip_file_name}.message"

                        cur_meter_dir="$BASE_DIR/$cur_date_dir/$meter"
                        new_zip_file_path="$cur_meter_dir/$new_zip_file_name"
                        new_message_file_path="$cur_meter_dir/$new_message_file_name"

                        original_zip_file_path="$cur_meter_dir/$zip_filename"
                        original_message_file_path="$message_file"

                        # Repackage the .zip file with the new naming convention
                        if repackage_event_file "$original_zip_file_path" "$new_zip_file_path" "$new_dir_name"; then
                            # Rename the .message file with the new naming convention
                            mv "$original_message_file_path" "$new_message_file_path" && echo "Renamed: $original_message_file_path to $new_message_file_path" || echo "Failed to rename: $original_message_file_path"

                            # Remove the original zip file if desired
                            rm -f "$original_zip_file_path" && echo "Removed: $original_zip_file_path" || echo "Failed to remove: $original_zip_file_path"
                        else
                            echo "Failed to repackage: $original_zip_file_path"
                        fi
                    fi
                done
            fi
        done
    fi     
done
echo "Done processing event files"
