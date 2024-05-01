#!/bin/bash

### HEADER ###
current_dir=$(dirname "$(readlink -f "$0")")
# Source the commons.sh file
source "$current_dir/commons.sh"

LOCKFILE="/var/lock/`basename $0`" # Define the lock file path using scripts basename

# ON START
_prepare_locking 

### BEGINING OF SCRIPT ###
 
# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking

# To be optionally be overriden by flags
config_path=""
download_dir=""

# Check if no command line arguments were provided
if [ "$#" -eq 0 ]; then
    show_help_flag "-d"
fi

# Parse command line arguments for --config/-c and --download_dir/-d flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -c | --config)
        if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
            show_help_flag "-d"
        fi
        config_path="$2"
        shift 2
        ;;
    -d | --download_dir)
        if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
            show_help_flag "-d"
        fi
        download_dir="$2"
        shift 2
        ;;
    -h | --help)
        show_help_flag "-d"
        ;;
    *)
        log "Unknown parameter passed: $1"
        show_help_flag "-d"
        ;;
    esac
done

# Make sure the output config file exists
if [ -f "$config_path" ]; then
    log "Config file exists at: $config_path"
else
    fail "Config: Config file does not exist."
fi

# Read values from the config file if not overridden by command-line args
if [ -z "$download_dir" ]; then
    download_dir=$(yq '.download_directory' "$config_path")
    if [ -z "$download_dir" ]; then
        fail "Config: Download directory cannot be null or empty, check config or add the download flag -d"
    fi
fi

# Read the config file
default_username=$(yq '.credentials.username' "$config_path")
default_password=$(yq '.credentials.password' "$config_path")
num_meters=$(yq '.meters | length' "$config_path")
location=$(yq '.location' "$config_path")
data_type=$(yq '.data_type' "$config_path")

# Check for null or empty values
[[ -z "$default_username" ]] && fail "Config: Default username cannot be null or empty."
[[ -z "$default_password" ]] && fail "Config: Default password cannot be null or empty."
[[ -z "$num_meters" || "$num_meters" -eq 0 ]] && fail "Config: Must have at least 1 meter in the config file."
[[ -z "$location" ]] && fail "Config: Location cannot be null or empty."
[[ -z "$data_type" ]] && fail "Config: Data type cannot be null or empty."

output_dir="$download_dir/$location/$data_type"

# Create the directory if it doesn't exist
mkdir -p "$output_dir"
if [ $? -eq 0 ]; then
    log "Directory created successfully: $output_dir"
else
    fail "Failed to create directory: $output_dir"
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

    # Execute download script and check its success in one step
    if "$current_dir/meters/$meter_type/download.sh" "$meter_ip" "$output_dir" "$meter_id" "$meter_type"; then
        log "Download complete for meter: $meter_id"
    else
        log "Download failed for meter: $meter_id. Moving to next meter."
        echo "" # Add a newline readability
        # Skip to the next iteration of the loop
        continue
    fi
done
