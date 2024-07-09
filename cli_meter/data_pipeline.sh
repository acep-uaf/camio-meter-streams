#!/bin/bash
# ==============================================================================
# Script Name:        data_pipeline.sh
# Description:        This script is a wrapper for the download process. It
#                     loops through the meters listed in the configuration file
#                     and downloads event files using the appropriate credentials.
#
# Usage:              ./data_pipeline.sh -c <config_path>
#
# Arguments:
#   -c, --config       Path to the configuration file
#   -h, --help         Show usage information
#
# Requirements:       yq
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

# Read the config file
download_dir=$(yq '.download_directory' "$config_path")
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")
bandwidth_limit=$(yq '.bandwidth_limit' "$config_path")
max_age_days=$(yq '.max_age_days' "$config_path")

# Check for null or empty values
[[ -z "$download_dir" || "$download_dir" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Download directory cannot be null or empty."
[[ -z "$default_username" || "$default_username" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Default username cannot be null or empty."
[[ -z "$default_password" || "$default_password" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Default password cannot be null or empty."
[[ -z "$location" || "$location" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Location cannot be null or empty."
[[ -z "$data_type" || "$data_type" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Data type cannot be null or empty."
[[ -z "$bandwidth_limit" || "$bandwidth_limit" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Bandwidth limit cannot be null or empty."
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && failure $STREAMS_INVALID_CONFIG "Must have at least 1 meter in the config file."
[[ -z "$max_age_days" || "$max_age_days" == "null" ]] && failure $STREAMS_INVALID_CONFIG "Max age days cannot be null or empty."  # New validation for max_age_days

# Create the base output directory
output_dir="$download_dir/$location/$data_type"
mkdir -p "$output_dir" && log "Directory created successfully: $output_dir" || failure $STREAMS_DIR_CREATION_FAIL "Failed to create directory: $output_dir"

# Loop through the meters and download the event files
for ((i = 0; i < num_meters; i++)); do
    meter_type=$(yq ".meters[$i].type" $config_path)
    meter_ip=$(yq ".meters[$i].ip" $config_path)
    meter_id=$(yq ".meters[$i].id" $config_path)

    # Use the default credentials if specific meter credentials are not provided
    meter_username=$(yq ".meters[$i].credentials.username // strenv(default_username)" $config_path)
    meter_password=$(yq ".meters[$i].credentials.password // strenv(default_password)" $config_path)

    # Set environment variables
    export USERNAME=${meter_username:-$default_username}
    export PASSWORD=${meter_password:-$default_password}

    # Execute download script and check its success in one step
    if "$current_dir/meters/$meter_type/download.sh" "$meter_ip" "$output_dir" "$meter_id" "$meter_type" "$bandwidth_limit" "$data_type" "$location" "$max_age_days" ; then
        log "Download complete for meter: $meter_id"
    else
        warning "Download incomplete for meter: $meter_id"
    fi
done

log "All meters have been processed"
