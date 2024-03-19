#!/bin/bash

# Source the commons.sh file
source commons.sh

# TODO: Change this path when ready to deploy
config_path="./config/acep-data-streams/kea/events/sel735_config.yml"

# Get the current date in YYYY-MM format
date=$(date '+%Y-%m')

# Make sure the output config file exists
if [ -f "$config_path" ]; then
    log "Config file exists at: $config_path."
else
    log "Config file does not exist." "err"
    exit 1
fi

# Read the config file
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")
download_dir=$(yq '.download_directory' "$config_path")

# Check for null or empty values
[[ -z "$default_username" ]] && exit_with_error "Default username cannot be null or empty."
[[ -z "$default_password" ]] && exit_with_error "Default password cannot be null or empty."
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && exit_with_error "Must have at least 1 meter in the config file."
[[ -z "$location" ]] && exit_with_error "Location cannot be null or empty."
[[ -z "$data_type" ]] && exit_with_error "Data type cannot be null or empty."



# Adjust output_dir based on download_directory from config
if [[ -n "$download_dir" ]]; then
    output_dir="$download_dir/$location/$data_type/$date"
else
    output_dir="$location/$data_type/$date"
fi

# Create the directory if it doesn't exist
mkdir -p "$output_dir"
if [ $? -eq 0 ]; then
    log "Directory created successfully: $output_dir"
else
    log "Failed to create directory: $output_dir" "err"
fi

# Loop through the meters and download the event files
for ((i = 0; i < num_meters; i++)); do
    meter_type=$(yq ".meters[$i].type" "$config_path")
    meter_ip=$(yq ".meters[$i].ip" "$config_path")
    meter_id=$(yq ".meters[$i].id" "$config_path")

    # Use the default credentials if specific meter credentials are not provided
    meter_username=$(yq ".meters[$i].username // strenv(default_username)" "$config_path")
    meter_password=$(yq ".meters[$i].password // strenv(default_password)" "$config_path")

    # Set environment variables
    export USERNAME=${meter_username:-$default_username}
    export PASSWORD=${meter_password:-$default_password}

    # Before calling the download script, set current_event_dir
    current_event_dir="$output_dir/$meter_id"

    # Execute download script
    "meters/$meter_type/download.sh" "$meter_ip" "$current_event_dir" "$meter_id" "$meter_type"

    # Reset current_event_dir
    current_event_dir=""

done

echo "Finished downloading events!!!!!!!!"
