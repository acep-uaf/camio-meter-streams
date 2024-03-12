#!/bin/bash

# This file is a wrapper script for the data pipeline

# Source the commons.sh file
source commons.sh

config_path="./acep-data-streams/kea/events/sel735_config.yml"

# Make sure the output config file exists
if [ -f "$config_path" ]; then
    log "Config file exists."
else
    log "Config file does not exist." "err"
    exit 1
fi

# Get the current date in YYYY-MM format
date=$(date '+%Y-%m')

# Read the config file
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")
output_dir="$location/$data_type/$date"

# Create the directory if it doesn't exist
mkdir -p "$output_dir"

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
    export REMOTE_METER_PATH=$(yq ".remote_directory" "$config_path")

    # Execute download script
    "meters/$meter_type/download.sh" "$meter_ip" "$output_dir/$meter_id"

done
