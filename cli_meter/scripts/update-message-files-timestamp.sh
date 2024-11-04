#!/bin/bash
# ==============================================================================
# Script Name:        update-message-files-with-timestamp.sh
#
# Description:        This script processes .message files to add an
#                     "event_timestamp" field if missing. It will unzip,
#                     extract the timestamp from metadata.yml, and repackage.
#
# Usage:              ./update-message-files-with-timestamp.sh <BASE_DIR>
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

BASE_DIR="$1"
updated_count=0
skipped_count=0

# Function to extract event_timestamp from metadata.yml
extract_event_timestamp() {
    local metadata_file="$1"
    grep "event_timestamp:" "$metadata_file" | awk '{print $2}' | tr -d '"'
}

# Function to add event_timestamp to the message file if missing
add_event_timestamp_to_message_file() {
    local message_file="$1"
    local event_timestamp="$2"
    
    # Update the message file to add "event_timestamp"
    jq --arg event_timestamp "$event_timestamp" '.event_timestamp = $event_timestamp' "$message_file" > "$message_file.tmp" && mv "$message_file.tmp" "$message_file"
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
                
                for message_file in "$meter_dir"/*.zip.message; do
                    if [ -f "$message_file" ]; then
                        # Check if event_timestamp already exists in the message file
                        if jq -e '.event_timestamp' "$message_file" > /dev/null 2>&1; then
                            skipped_count=$((skipped_count + 1))
                            continue
                        fi
                        
                        # Derive the path of the corresponding .zip file by removing .message
                        zip_file="${message_file%.message}"
                        if [ ! -f "$zip_file" ]; then
                            echo "Zip file not found for $message_file, skipping"
                            continue
                        fi
                        
                        # Unzip the original file into a temporary directory
                        temp_dir=$(mktemp -d) || { echo "Failed to create temporary directory"; exit 1; }
                        unzip -q "$zip_file" -d "$temp_dir" || { echo "Failed to unzip: $zip_file"; rm -rf "$temp_dir"; continue; }

                        # Extract event_id from the .message file
                        event_id=$(jq -r '.event_id' "$message_file")
                        echo "event_id: $event_id"

                        # Find metadata.yml in the extracted contents
                        metadata_file="$temp_dir/${event_id}_metadata.yml"
                        if [ ! -f "$metadata_file" ]; then
                            echo "Metadata file not found in $zip_file, skipping"
                            rm -rf "$temp_dir"
                            continue
                        fi
                        
                        # Extract event_timestamp from metadata.yml
                        event_timestamp=$(extract_event_timestamp "$metadata_file")
                        if [ -z "$event_timestamp" ]; then
                            echo "No event_timestamp found in $metadata_file, skipping"
                            rm -rf "$temp_dir"
                            continue
                        fi
                        
                        # Add event_timestamp to the message file
                        add_event_timestamp_to_message_file "$message_file" "$event_timestamp"
                        
                        # Rezip the contents back into the original .zip file
                        (cd "$temp_dir" && zip -r -q "$zip_file" .) && echo "Repackaged back to original file: $zip_file"
                        
                        # Clean up temporary directory
                        rm -rf "$temp_dir"
                    fi
                done
            fi
        done
    fi
done

# Print the tally of updated and skipped files
echo -e "\nFinished processing message files in: $BASE_DIR\n"
echo "Summary of Processed Message Files:"
echo "Files updated with 'event_timestamp': $updated_count"
echo "Files already complete (skipped): $skipped_count"

# If no files were processed
if [ "$updated_count" -eq 0 ] && [ "$skipped_count" -eq 0 ]; then
    echo "No message files were found or processed."
fi