#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System)

# Check command line arguments
if [ $# -ne 4 ]; then
    fail "Usage: $0 <src_dir> <dest_dir> <dest_user> <dest_host>"
fi

src_dir="$1"
dest_dir="$2"
dest_user="$3"
dest_host="$4"

# Define source and destination directories
current_dir=$(dirname "$(readlink -f "$0")")
MIN_BYTES_SENT=666

# Source the commons.sh file
source "$current_dir/commons.sh"

# Create source and destination directories if they don't exist
# Ensure remote directory exists using SSH
ssh "$dest_user@$dest_host" "mkdir -p '$dest_dir'" || { fail "Failed to create remote directory"; }
#mkdir -p "$dest_dir"

# Populate the source directory with sample files if it's empty
if [ -d "$src_dir" ] && [ -n "$(ls -A $src_dir)" ]; then
    log "Attempting to transfer data from: $src_dir to $dest_dir"
    # on $dest_host as $dest_user"

    # -a : Archive mode to preserve attributes and copy directories recursively
    # -v : Verbose mode to see what rsync is doing
    # --delete : Deletes extraneous files from destination to make it exactly match the source
    # --ignore-existing : Skip updating files that exist on the destination
    rsync_output=$(rsync -av --delete --ignore-existing "$src_dir" "$dest_user@$dest_host:$dest_dir")

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

                # echo's to archive_pipeline.sh to parse and publish to MQTT
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
