#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System)

# Check command line arguments
if [ $# -ne 5 ]; then
    fail "Usage: $0 <src_dir> <dest_dir> <dest_host> <dest_user> <bwlimit>"
fi

src_dir=$1
dest_dir=$2
dest_host=$3
dest_user=$4
bwlimit=$5

# Define source and destination directories
current_dir=$(dirname "$(readlink -f "$0")")

# Source the commons.sh file
source "$current_dir/commons.sh"

# Check if the source directory exists and is not empty
if [ -d "$src_dir" ] && [ -n "$(ls -A $src_dir)" ]; then
    log "Attempting to transfer data from: $src_dir to $dest_dir on $dest_host as $dest_user"

    # Sync files from local to remote server using rsync
    #   -a : Archive mode to preserve attributes and copy directories recursively
    #   -v : Verbose mode to see what rsync is doing
    #   --bwlimit : Limit I/O bandwidth (kbps)
    #   --exclude : Exclude the 'working' directory

    rsync_output=$(rsync -av --bwlimit=$bwlimit --exclude 'working' $src_dir $dest_user@$dest_host:$dest_dir)
    log "$rsync_output"

    # Check the status of the rsync command
    if [ $? -eq 0 ]; then
        echo "$rsync_output" | grep '.zip$' | while IFS= read -r line; do

            # Extract the filename
            filename=$(basename "$line")
            # Extract the path without the filename
            path=$(dirname "$line")
            event_id=$(echo $filename | cut -d'_' -f1)

            # echo's to archive_pipeline.sh to parse and publish to MQTT
            echo $event_id,$filename,$path

        done

        log "Data synchronization completed successfully"

    else
        fail "Data synchronization failed"
    fi
else
    fail "Source directory doesn't exist or is empty"
fi
