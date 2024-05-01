#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System)
# and publish message to MQTT broker

# Define the current directory
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"

LOCKFILE="/var/lock/`basename $0`" # Define the lock file path using scripts basename

# ON START
_prepare_locking 

### BEGINING OF SCRIPT ###
 
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
src_dir=$(yq e '.archive.source.directory' "$config_path")
dest_dir=$(yq e '.archive.destination.directory' "$config_path")
bwlimit=$(yq e '.archive.destination.bandwidth_limit' "$config_path")
dest_host=$(yq e '.archive.destination.host' "$config_path")
dest_user=$(yq e '.archive.destination.user' "$config_path")

mqtt_broker=$(yq e '.mqtt.connection.host' "$config_path")
mqtt_port=$(yq e '.mqtt.connection.port' "$config_path")
mqtt_topic=$(yq e '.mqtt.topic.name' "$config_path")

# Check for null or empty values
[[ -z "$src_dir" ]] && fail "Config: Source directory cannot be null or empty."
[[ -z "$dest_dir" ]] && fail "Config: Destination directory cannot be null or empty."
[[ -z "$dest_user" ]] && fail "Config: Destination user cannot be null or empty."
[[ -z "$dest_host" ]] && fail "Config: Destination host cannot be null or empty."
[[ -z "$mqtt_broker" ]] && fail "Config: MQTT broker cannot be null or empty."
[[ -z "$mqtt_port" || ! "$mqtt_port" =~ ^[0-9]+$ ]] && fail "Config: MQTT port must be a valid number."
[[ -z "$mqtt_topic" ]] && fail "Config: MQTT topic cannot be null or empty."

# Archive the downloaded files
"$current_dir/archive_data.sh" "$src_dir" "$dest_dir" "$dest_host" "$dest_user" "$bwlimit" | while IFS= read -r event_id; do
    # Publish the event ID to the MQTT broker
    "$current_dir/mqtt_pub.sh" "$mqtt_broker" "$mqtt_port" "$mqtt_topic" "$event_id"
done
