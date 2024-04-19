#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System)

# Check command line arguments
if [ $# -ne 2 ]; then
    fail "Usage: $0 <source_dir> <destination_dir>"
fi

# MQTT Broker settings
source_dir="$1"
destination_dir="$2"

# Define source and destination directories
current_dir=$(dirname "$(readlink -f "$0")")
MIN_BYTES_SENT=259

# Source the commons.sh file
source "$current_dir/commons.sh"

# Create source and destination directories if they don't exist
mkdir -p "$destination_dir"

# Populate the source directory with sample files if it's empty
if [ -d "$source_dir" ] && [ -n "$(ls -A $source_dir)" ]; then
    log "rsync moving data from $source_dir to $destination_dir"

    # -a : Archive mode to preserve attributes and copy directories recursively
    # -v : Verbose mode to see what rsync is doing
    # --delete : Deletes extraneous files from destination to make it exactly match the source
    rsync_output=$(rsync -av --delete --ignore-existing "$source_dir" "$destination_dir")

    # Check the status of the rsync command
    if [ $? -eq 0 ]; then
        # Parse and display the number of sent bytes
        sent_bytes=$(echo "$rsync_output" | grep -oP 'sent \K[0-9,]+' | tr -d ',')

        if [ "$sent_bytes" -gt "$MIN_BYTES_SENT" ]; then
            # Parse output to extract filenames or just the numeric part before .zip
            echo "$rsync_output" | grep -E '\.zip$' | while IFS= read -r line; do

                # Extract the filename & event_id
                filename=$(echo "$line" | awk -F/ '{print $NF}')
                event_id=$(echo "$filename" | sed 's/\.zip$//')
                echo $event_id

            done

            log "Data synchronization completed successfully"
        else
            log "No files to transfer - directories are already in sync"
        fi
    else
        fail "Data synchronization failed"
    fi
else
    fail "Source directory doesn't exist or is empty"
fi
