#!/bin/bash

# Source the commons.sh file
source commons.sh

config_path="/etc/acep-data-streams/config.yml"
download_dir="" # To be potentially overriden by flags

# Parse command line arguments for --config/-c and --download_dir/-d flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --config | -c)
        config_path="$2"
        shift 2
        ;;
    --download_dir | -d)
        download_dir="$2"
        shift 2
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
done

# Make sure the output config file exists
if [ -f "$config_path" ]; then
    log "Config file exists at: "$config_path"."
else
    log "Config file does not exist." "err"
    exit 1
fi

# Read values from the config file if not overridden by command-line args
if [ -z "$download_dir" ]; then
    download_dir=$(yq '.download_directory' "$config_path")
fi

# Read the config file
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")

# Check for null or empty values
[[ -z "$default_username" ]] && exit_with_error "Default username cannot be null or empty."
[[ -z "$default_password" ]] && exit_with_error "Default password cannot be null or empty."
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && exit_with_error "Must have at least 1 meter in the config file."
[[ -z "$location" ]] && exit_with_error "Location cannot be null or empty."
[[ -z "$data_type" ]] && exit_with_error "Data type cannot be null or empty."

output_dir="$download_dir/$location/$data_type"


# Create the directory if it doesn't exist
mkdir -p "$output_dir"
if [ $? -eq 0 ]; then
    log "Directory created successfully: $output_dir"
else
    log "Failed to create directory: $output_dir" "err"
fi


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

    echo "Processing meter: $meter_id with IP: $meter_ip"

    current_dir=$(dirname "$(readlink -f "$0")")
    # Optionally, check and attempt to redownload incomplete downloads before starting new downloads for this meter
    source "${current_dir}/check_missing.sh" "$meter_ip" "$output_dir/$meter_id" "$meter_id" "$meter_type" "$meter_ip"

    # Execute download script
    "meters/$meter_type/download.sh" "$meter_ip" "$output_dir" "$meter_id" "$meter_type" 

    # Optionally, check for incomplete downloads again after attempting new downloads for this meter
    source "${current_dir}/check_missing.sh" "$meter_ip" "$output_dir/$meter_id" "$meter_id" "$meter_type" "$meter_ip"
    echo "Completed processing for meter $meter_id"
done

# Check if the loop completed successfully or was interrupted
if [ $? -eq 0 ]; then
    echo "Download complete to : $output_dir"
else
    echo "Failed to Download"
fi
