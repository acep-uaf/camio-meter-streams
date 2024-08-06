#!/bin/bash
# ==============================================================================
# Script Name:        repackage-event-files.sh
#
# Description:        This script unzips, renames, and re-zips event files
#                     in DAS for .zip and .message files to achieve a new
#                     naming convention. 
#
# Naming Convention:  location-data_type-meter-YYYYMM-event_id
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
# Requirements:       jq, unzip, zip, md5sum
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
    local event_id=$(jq -r '.id' "$message_file")
    local zip_filename=$(jq -r '.filename' "$message_file")
    local data_type=$(jq -r '.data_type' "$message_file")

    echo "$event_id" "$zip_filename" "$data_type"
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

# Function to calculate md5sum of a file
calculate_md5sum() {
    local file="$1"
    md5sum "$file" | awk '{ print $1 }'
}

# Function to create a new message file with updated format
create_new_message_file() {
    local new_message_file_path="$1"
    local event_id="$2"
    local new_zip_file_name="$3"
    local md5sum_value="$4"
    local data_type="$5"

    jq -n \
       --arg event_id "$event_id" \
       --arg filename "$new_zip_file_name" \
       --arg md5sum "$md5sum_value" \
       --arg data_type "$data_type" \
       '{event_id: $event_id, filename: $filename, md5sum: $md5sum, data_type: $data_type}' > "$new_message_file_path" && echo "Created new message file: $new_message_file_path" || echo "Failed to create new message file: $new_message_file_path"
}

# Main script logic to process directories and files
for date_dir in "$BASE_DIR"/*; do
    if [ -d "$date_dir" ]; then
        echo "Processing date directory: $date_dir"
        cur_date_dir=$(basename "$date_dir")
        # Format date directory to remove hyphens Ex: 2024-01 -> 202401
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
                        read event_id zip_filename data_type <<< $(parse_message_file "$message_file")

                        # Parse location from path (first path) Ex: kea/path/to
                        location=$(echo "$path" | cut -d'/' -f1)

                        # New naming conventions example: kea-events-meter1-202401-12345
                        new_dir_name="${location}-${data_type}-${meter}-${fmt_date_dir}-${event_id}"
                        new_zip_file_name="${new_dir_name}.zip"
                        new_message_file_name="${new_zip_file_name}.message"

                        cur_meter_dir="$BASE_DIR/$cur_date_dir/$meter"
                        new_zip_file_path="$cur_meter_dir/$new_zip_file_name"
                        original_zip_file_path="$cur_meter_dir/$zip_filename"

                        # Repackage the .zip file with the new naming convention
                        if repackage_event_file "$original_zip_file_path" "$new_zip_file_path" "$new_dir_name"; then
                            # Calculate the md5sum of the new zip file
                            md5sum_value=$(calculate_md5sum "$new_zip_file_path")

                            # Create the new message file with the updated format
                            create_new_message_file "$cur_meter_dir/$new_message_file_name" "$event_id" "$new_zip_file_name" "$md5sum_value" "$data_type"

                            # Remove the original zip and message files if desired
                            rm -f "$original_zip_file_path" && echo "Removed: $original_zip_file_path" || echo "Failed to remove: $original_zip_file_path"
                            rm -f "$message_file" && echo "Removed: $message_file" || echo "Failed to remove: $message_file"
                        else
                            echo "Failed to repackage: $original_zip_file_path"
                        fi
                    fi
                done
            fi
        done
    fi     
done

echo "Finished updating directory: $BASE_DIR"