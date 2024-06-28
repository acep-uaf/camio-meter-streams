#!/bin/bash
# ==============================================================================
# Script Name:        data_pipeline.sh
# Description:        This script is a wrapper for the download process. It
#                     loops through the meters listed in the configuration file
#                     and downloads event files using the appropriate credentials.
#
# Usage:              ./data_pipeline.sh -c <config_path> [-d <download_dir>]
#
# Arguments:
#   -c, --config       Path to the configuration file
#   -d, --download_dir Optional: Override the download directory from the config
#   -h, --help         Show usage information
#
# Requirements:       yq
#                     commons.sh
# ==============================================================================

current_dir=$(dirname "$(readlink -f "$0")")
# Source the commons.sh file
source "$current_dir/commons.sh"

LOCKFILE="/var/lock/`basename $0`" # Define the lock file path using script's basename

# On start
_prepare_locking 
 
# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# Parse the config path argument
config_path=$(parse_config_arg "$@") || exit 1

# Make sure the output config file exists
[ -f "$config_path" ] && log "Config file exists at: $config_path" || fail "Config: Config file does not exist."

# Read the config file
download_dir=$(yq '.download_directory' "$config_path")
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")
bandwidth_limit=$(yq '.bandwidth_limit' "$config_path")

# Check for null or empty values
[ -z "$download_dir" ] && fail "Config: Download directory cannot be null or empty."
[[ -z "$default_username" ]] && fail "Config: Default username cannot be null or empty."
[[ -z "$default_password" ]] && fail "Config: Default password cannot be null or empty."
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && fail "Config: Must have at least 1 meter in the config file."
[[ -z "$location" ]] && fail "Config: Location cannot be null or empty."
[[ -z "$data_type" ]] && fail "Config: Data type cannot be null or empty."
[[ -z "$bandwidth_limit" ]] && fail "Config: Bandwidth limit cannot be null or empty."

# Create the base output directory
output_dir="$download_dir/$location/$data_type"
mkdir -p "$output_dir" && log "Directory created successfully: $output_dir" || fail "Failed to create directory: $output_dir"

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
    if "$current_dir/meters/$meter_type/download.sh" "$meter_ip" "$output_dir" "$meter_id" "$meter_type" "$bandwidth_limit" "$data_type" "$location"; then
        log "Download complete for meter: $meter_id"
    else
        log "[WARNING] Download not complete for meter: $meter_id. Moving to next meter."
        log "" # Add a newline readability
    fi
done
