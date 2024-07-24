#!/bin/bash
# ==============================================================================
# Script Name:        archive_data.sh
# Description:        This script uses rsync to move data from the local machine
#                     to the Data Acquisition System (DAS) and returns metadata
#                     to the calling script to create a .message file.
#
# Usage:              ./archive_data.sh <src_dir> <dest_dir> <dest_host> <dest_user> <bwlimit> <ssh_key_path>
#
# Arguments:
#   src_dir           Source directory containing the data to be archived
#   dest_dir          Destination directory on the DAS
#   dest_host         Hostname or IP address of the DAS
#   dest_user         Username to connect to the DAS
#   bwlimit           Bandwidth limit for rsync (in kbps)
#   ssh_key_path      Path to the SSH key for authentication
#
# Called by:          archive_pipeline.sh
#
# Requirements:       rsync
#                     commons.sh
# ==============================================================================

# Check command line arguments
if [ $# -ne 6 ]; then
    fail "Usage: $0 <src_dir> <dest_dir> <dest_host> <dest_user> <bwlimit> <ssh_key_path>"
fi

src_dir=$1
dest_dir=$2
dest_host=$3
dest_user=$4
bwlimit=$5
ssh_key_path=$6

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

    rsync_output=$(rsync -av --bwlimit=$bwlimit -e "ssh -i $ssh_key_path" --exclude 'working' $src_dir $dest_user@$dest_host:$dest_dir)
    log "$rsync_output"

    # Check the status of the rsync command
    if [ $? -eq 0 ]; then
        echo "$rsync_output" | grep '.zip$' | while IFS= read -r line; do

            # Extract the filename, id and path
            filename=$(basename "$line")
            path=$(dirname "$line")
            id="${filename%.zip}"

            # echo to archive_pipeline.sh to parse create .message file
            echo "$id,$filename,$path"

        done

        log "Data synchronization completed successfully"

    else
        fail "Data synchronization failed"
    fi
else
    fail "Source directory doesn't exist or is empty"
fi
