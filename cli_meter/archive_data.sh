#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System)

# Define source and destination directories
current_dir=$(dirname "$(readlink -f "$0")")
MIN_BYTES_SENT=259

# Source the commons.sh file
source "$current_dir/commons.sh"

SOURCE_DIR="$current_dir/../data/kea/events/level0/"
DESTINATION_DIR="$current_dir/../data_archive/kea/events/level0/"

# Create source and destination directories if they don't exist
mkdir -p "$DESTINATION_DIR"

# Populate the source directory with sample files if it's empty
if [ -d "$SOURCE_DIR" ] && [ -n "$(ls -A $SOURCE_DIR)" ]; then
    log "rsync moving data from $SOURCE_DIR to $DESTINATION_DIR"

    # -a : Archive mode to preserve attributes and copy directories recursively
    # -v : Verbose mode to see what rsync is doing
    # --delete : Deletes extraneous files from destination to make it exactly match the source
    rsync_output=$(rsync -av --delete --ignore-existing "$SOURCE_DIR" "$DESTINATION_DIR")

    # Check the status of the rsync command
    if [ $? -eq 0 ]; then
        # Parse and display the number of sent bytes
        sent_bytes=$(echo "$rsync_output" | grep -oP 'sent \K[0-9,]+')
        if [ "$sent_bytes" -eq "$MIN_BYTES_SENT" ]; then
            echo "No files transferred - directories are already in sync."
            exit 0
        else  
            echo "Sent $sent_bytes bytes"
            # Parse output to extract filenames or just the numeric part before .zip
            echo "$rsync_output" | grep -E '\.zip$' | while IFS= read -r line; do
                # Extract the filename
                filename=$(echo "$line" | awk -F/ '{print $NF}')
                echo "Filename: $filename"

                # Extract the event_id before .zip
                event_id=$(echo "$filename" | sed 's/\.zip$//')
                echo "Number: $event_id"

                # Call another script or command with $filename or $event_id
                # ./another_script.sh "$filename"

                # ./another_script.sh "$event_id"
            done
            log "Data synchronization completed successfully."
        fi
    else
        fail "Data synchronization failed."
    fi
else
    fail "Source directory doesn't exist or is empty"
fi
