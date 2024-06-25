#!/bin/bash
# ==============================================================================
# Script Name:        archive_pipeline.sh
# Description:        This script handles the archive process, moving data from 
#                     multiple local sources to their respective remote destinations.
#                     It includes functionality to parse configuration, lock 
#                     the process, and transfer files using rsync.
#
# Usage:              ./archive_pipeline.sh -c <config_path>
#
# Arguments:
#   -c, --config      Path to the configuration file
#   -h, --help        Show usage information
#
# Requirements:       yq, jq, rsync
#                     commons.sh
# ==============================================================================

# Define the current directory
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"

# Define the lock file path
LOCKFILE="/var/lock/$(basename $0)"
_prepare_locking

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# Parse the config path argument
config_path=$(parse_config_arg "$@") || exit 1

# Make sure the output config file exists
[ -f "$config_path" ] && log "Config file exists at: $config_path" || fail "Config: Config file does not exist."

# Parse general configuration using yq
bwlimit=$(yq e '.bandwidth_limit // "0"' "$config_path")
dest_host=$(yq e '.host' "$config_path") 
dest_user=$(yq e '.credentials.user' "$config_path") 
ssh_key_path=$(yq e '.credentials.ssh_key_path' "$config_path") 

[[ -z "$dest_host" ]] && fail "Config: Destination host cannot be null or empty."
[[ -z "$dest_user" ]] && fail "Config: Destination user cannot be null or empty."
[[ -z "$ssh_key_path" ]] && fail "Config: SSH key path cannot be null or empty."

# Parse and process each directory pair using yq
num_dirs=$(yq e '.directories | length' "$config_path") # Get the number of directory pairs
for i in $(seq 0 $((num_dirs - 1))); do
    src_dir=$(yq e ".directories[$i].source" "$config_path") # Extract source directory for current pair
    dest_dir=$(yq e ".directories[$i].destination" "$config_path") # Extract destination directory for current pair

    # Check for null or empty values in directory configuration
    [[ -z "$src_dir" ]] && fail "Config: Source directory cannot be null or empty."
    [[ -z "$dest_dir" ]] && fail "Config: Destination directory cannot be null or empty."

    # Check if the source directory exists and is not empty
    if [ -d "$src_dir" ] && [ -n "$(ls -A "$src_dir")" ]; then
        log "Attempting to transfer data from: $src_dir to $dest_dir on $dest_host as $dest_user"

        # Construct rsync command
        rsync_command="rsync -av -e 'ssh -i $ssh_key_path' --bwlimit=$bwlimit --exclude 'working' \"$src_dir\" \"$dest_user@$dest_host:$dest_dir\"" # Basic rsync command with bandwidth limit

        # Execute rsync command
        rsync_output=$(eval $rsync_command) # Use eval to execute the constructed command
        log "$rsync_output"

        # Check the status of the rsync command
        if [ $? -eq 0 ]; then
            log "Data synchronization from $src_dir to $dest_dir completed successfully"
        else
            fail "Data synchronization from $src_dir to $dest_dir failed"
        fi
    else
        fail "Source directory $src_dir doesn't exist or is empty"
    fi
done

log "All specified directories have been processed."
