#!/bin/bash
# ==============================================================================
# Script Name:        archive_pipeline.sh
# Description:        This script is a wrapper for the archive process. It uses
#                     rsync to move data from the local machine to the Data
#                     Acquisition System (DAS).
#
# Usage:              ./archive_pipeline.sh -c <config_path>
#
# Arguments:
#   -c, --config      Path to the configuration file
#   -h, --help        Show usage information
#
# Called by:          User (direct execution)
#
# Requirements:       yq, jq
#                     commons.sh, archive_data.sh
# ==============================================================================

# Define the current directory
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"

# Define the lock file path
LOCKFILE="/var/lock/$(basename $0)" # Define the lock file path using scripts basename
_prepare_locking

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# To be optionally be overriden by flags
config_path=""

# Check if no command line arguments were provided
if [ "$#" -eq 0 ]; then
    show_help_flag
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -c | --config)
        if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
            log "Error: Missing value for the configuration path after '$1'."
            show_help_flag
        fi
        config_path="$2"
        shift 2
        ;;
    -h | --help)
        show_help_flag
        ;;
    *)
        log "Unknown parameter passed: $1"
        show_help_flag
        ;;
    esac
done

# Make sure a config path was set
if [[ -z "$config_path" ]]; then
    log "Config path must be specified."
    show_help_flag
fi

# Make sure the output config file exists
if [ -f "$config_path" ]; then
    log "Config file exists at: $config_path"
else
    fail "Config: Config file does not exist."
fi

# Parse configuration using yq
src_dir=$(yq e '.source.directory' "$config_path")
dest_dir=$(yq e '.destination.directory' "$config_path")
bwlimit=$(yq e '.destination.bandwidth_limit' "$config_path")
dest_host=$(yq e '.destination.host' "$config_path")
dest_user=$(yq e '.destination.credentials.user' "$config_path")
ssh_key_path=$(yq e '.destination.credentials.ssh_key_path' "$config_path")

# Check for null or empty values
[[ -z "$src_dir" ]] && fail "Config: Source directory cannot be null or empty."
[[ -z "$dest_dir" ]] && fail "Config: Destination directory cannot be null or empty."
[[ -z "$dest_user" ]] && fail "Config: Destination user cannot be null or empty."
[[ -z "$dest_host" ]] && fail "Config: Destination host cannot be null or empty."
[[ -z "$ssh_key_path" ]] && fail "Config: ssh_key_path topic cannot be null or empty."

# Archive the downloaded files and read output
"$current_dir/archive_data.sh" "$src_dir" "$dest_dir" "$dest_host" "$dest_user" "$bwlimit" "$ssh_key_path" | while IFS=, read -r id filename path; do

    # Check if variables are empty and log a warning if so
    if [ -z "$id" ] || [ -z "$filename" ] || [ -z "$path" ]; then
        log "Warning: One of the variables is empty. Event ID: '$id', Filename: '$filename', Path: '$path'"
    fi

    # Use jq to create a JSON payload
    json_payload=$(jq -n \
        --arg id "$id" \
        --arg fn "$filename" \
        --arg pth "$path" \
        '{id: $id, filename: $fn, path: $pth}')

    # Create a .message file with the JSON payload

done
