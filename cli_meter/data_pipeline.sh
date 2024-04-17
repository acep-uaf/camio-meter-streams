#!/bin/bash

### HEADER ###
current_dir=$(dirname "$(readlink -f "$0")")
# Source the commons.sh file
source "$current_dir/commons.sh"

LOCKFILE="/var/lock/`basename $0`" # Define the lock file path using scripts basename
LOCKFD=99 # Assign a high file descriptor number for locking 

# PRIVATE
_lock()             { flock -$1 $LOCKFD; } # Lock function: apply flock with given arg to LOCKFD
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; } # Cleanup function: unlock, remove lockfile
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; } # Ensure lock cleanup runs on script exit
_failed_locking()   { echo "Another instance is already running!"; exit 1; } # Error message for failed locking

# ON START
_prepare_locking 

# PUBLIC
exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

### BEGINING OF SCRIPT ###
 
# Try to lock exclusively without waiting; exit if another instance is running
exlock_now || _failed_locking


config_path=""
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
        fail "Unknown parameter passed: $1"
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
