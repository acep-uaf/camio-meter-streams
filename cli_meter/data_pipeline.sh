#!/bin/bash
# ==============================================================================
# Script Name:        data_pipeline.sh
# Description:        This script loops through the meters listed in the configuration
#                     file and downloads event files using the appropriate credentials.
#
# Usage:              ./data_pipeline.sh -c <config_path>
#
# Arguments:
#   -c, --config       Path to the configuration file
#   -h, --help         Show usage information
#
# Requirements:       yq
#                     commons.sh
# ==============================================================================

current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh" # Utility functions

LOCKFILE="/var/lock/$(basename $0)" # Define the lock file path using the script's basename

# ON START
_prepare_locking

# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

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
            log "Missing value for the configuration path after '$1'."
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

# Make sure the config file exists
if [ -f "$config_path" ]; then
    log "Config file exists at: $config_path"
else
    fail $EXIT_UNKNOWN "Config file not found at: $config_path"    
fi

# Read the config file into individual variables
base_download_dir=$(yq '.download_directory' "$config_path")
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")
bw_limit=$(yq '.bandwidth_limit // 0' "$config_path")  # Default to 0 if empty

# Validate configuration values
[[ -z "$base_download_dir" ]] && fail $EXIT_UNKNOWN "Download directory cannot be null or empty"
[[ -z "$default_username" ]] && fail $EXIT_UNKNOWN "Default username cannot be null or empty"
[[ -z "$default_password" ]] && fail $EXIT_UNKNOWN "Default password cannot be null or empty"
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && fail $EXIT_UNKNOWN "Must have at least 1 meter in the config file"
[[ -z "$location" ]] && fail $EXIT_UNKNOWN "Location cannot be null or empty"
[[ -z "$data_type" ]] && fail $EXIT_UNKNOWN "Data type cannot be null or empty"

output_dir="$base_download_dir/$location/$data_type"

# Create the directory if it doesn't exist
mkdir -p "$output_dir"
if [ $? -eq 0 ]; then
    log "Directory created: $output_dir"
else
    fail $EXIT_UNKNOWN "Failed to create directory: $output_dir"
fi

# Loop through the meters and download the event files
for ((i = 0; i < num_meters; i++)); do
    meter_type=$(yq ".meters[$i].type" "$config_path")
    meter_ip=$(yq ".meters[$i].ip" "$config_path")
    meter_id=$(yq ".meters[$i].id" "$config_path")

    # Validate meter_type, meter_ip, and meter_id are not null or empty
    if [[ -z "$meter_type" || -z "$meter_ip" || -z "$meter_id" ]]; then
        log "Meter configuration invalid at index $((i+1)): meter_type='$meter_type', meter_ip='$meter_ip', meter_id='$meter_id'"
        log "Skipping meter: $meter_id"
        continue  # Skip to the next meter if validation fails
    fi

    log "Processing meter: $meter_id"

    # Use the default credentials if specific meter credentials are not provided
    meter_username=$(yq ".meters[$i].credentials.username // strenv(default_username)" "$config_path")
    meter_password=$(yq ".meters[$i].credentials.password // strenv(default_password)" "$config_path")

    # Set environment variables for the download script
    export USERNAME=${meter_username:-$default_username}
    export PASSWORD=${meter_password:-$default_password}

    # Execute download script and capture its exit code and output
    if "$current_dir/meters/$meter_type/download.sh" "$meter_ip" "$output_dir" "$meter_id" "$meter_type" "$bw_limit" "$data_type" "$location"; then
        log "Download complete for meter: $meter_id"
    else
        exit_code=$?
        fail $exit_code "Download failed for meter: $meter_id - Exit code: $exit_code - Error: $error_message"
    fi
done

log "All meter downloads attempted. Download process complete."
