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
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/common_utils.sh"

LOCKFILE="/var/lock/$script_name" # Define the lock file path using script's basename

# Check for at least 1 argument
[ "$#" -lt 1 ] && show_help_flag && failure $STREAMS_INVALID_ARGS "No arguments provided"

# On start
_prepare_locking

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# Configuration file path
config_path=$(parse_config_arg "$@")
[ -f "$config_path" ] && log "Config file exists at: $config_path" || failure $STREAMS_FILE_NOT_FOUND "Config file does not exist"

# Parse general configuration using yq
bwlimit=$(yq e '.bandwidth_limit // "0"' "$config_path")
dest_host=$(yq e '.host' "$config_path") 
dest_user=$(yq e '.credentials.user' "$config_path") 
ssh_key_path=$(yq e '.credentials.ssh_key_path' "$config_path") 

[[ -z "$dest_host" || "$dest_host" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Destination host cannot be null or empty."
[[ -z "$dest_user" || "$dest_user" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Destination user cannot be null or empty."
[[ -z "$ssh_key_path" || "$ssh_key_path" == "null" ]] && failure $STREAMS_INVALID_CONFIG "SSH key path cannot be null or empty."

# Parse and process each directory pair using yq
num_dirs=$(yq e '.directories | length' "$config_path") # Get the number of directory pairs
for i in $(seq 0 $((num_dirs - 1))); do
    src_dir=$(yq e ".directories[$i].source" "$config_path") # Extract source directory for current pair
    dest_dir=$(yq e ".directories[$i].destination" "$config_path") # Extract destination directory for current pair

    # Check for null or empty values in directory configuration
    [[ -z "$src_dir" ]] && failure $STREAMS_INVALID_CONFIG "Source directory cannot be null or empty."
    [[ -z "$dest_dir" ]] && failure $STREAMS_INVALID_CONFIG "Destination directory cannot be null or empty."

    # Check if the source directory exists and is not empty
    if [ -d "$src_dir" ] && [ -n "$(ls -A "$src_dir")" ]; then
        log "Transfering data from: $src_dir to $dest_dir on $dest_host as $dest_user"

        rsync -av -e 'ssh -i $ssh_key_path' --bwlimit=$bwlimit --exclude 'working' "$src_dir" "$dest_user@$dest_host:$dest_dir"
        rsync_status=$?

        # Check the status of the rsync command
        [ $rsync_status -eq 0 ] && log "Data transfer from $src_dir to $dest_host completed successfully" || failure $STREAMS_RSYNC_FAIL "Data synchronization from $src_dir to $dest_host failed"
    else
        failure $STREAMS_DIR_NOT_FOUND "Source directory $src_dir doesn't exist or is empty"
    fi
done

log "All specified directories have been processed."

# If cleanup is enabled in the configuration, run the cleanup script
enable_cleanup=$(yq e '.enable_cleanup' "$config_path")
[ "$enable_cleanup" ] && source "$current_dir/cleanup.sh" -c "$config_path" || log "Cleanup is disabled."


