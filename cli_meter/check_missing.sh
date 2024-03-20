#!/bin/bash

# Check if exactly four arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type>"
    exit 1
fi

# Assign arguments to variables
meter_ip=$1
output_dir=$2
meter_id=$3
meter_type=$4
download_progress_dir="$output_dir/.download_progress"
event_dir_path="$output_dir/level0"

echo "Checking for missing files..."

# Check for events marked as in progress but not completed
if [ -d "$download_progress_dir/in_progress" ]; then
    for in_progress_event in "$download_progress_dir/in_progress/"*; do
        event_id=$(basename "$in_progress_event")
        event_path="$event_dir_path/$event_id"

        echo "Attempting to redownload event: $event_id due to incomplete download."

        # Execute download script for the specific event
        bash "meters/$meter_type/download_missing_file.sh" "$event_path" "$event_id" "$meter_id" "$meter_type" "$download_progress_dir"

        if [ $? -eq 0 ]; then
            echo "Successfully redownloaded files for event: $event_id"
        else
            echo "Failed to redownload files for event: $event_id"
        fi
    done
else
    echo "No in-progress downloads found to check or redownload."
fi
