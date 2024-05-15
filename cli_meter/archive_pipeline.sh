#!/bin/bash
# ==============================================================================
# Script Name:        archive_pipeline.sh
# Description:        This script is a wrapper for the archive process. It uses
#                     rsync to move data from the local machine to the Data
#                     Acquisition System (DAS) and uses mosquitto-clients publishes messages to an MQTT broker.
#
# Usage:              ./archive_pipeline.sh -c <config_path>
#
# Arguments:
#   -c, --config      Path to the configuration file
#   -h, --help        Show usage information
#
# Called by:          User (direct execution)
#
# Requirements:       yq, jq, mosquitto-clients
#                     commons.sh, archive_data.sh, mqtt_pub.sh
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
src_dir=$(yq e '.archive.source.directory' "$config_path")
dest_dir=$(yq e '.archive.destination.directory' "$config_path")
bwlimit=$(yq e '.archive.destination.bandwidth_limit' "$config_path")
dest_host=$(yq e '.archive.destination.host' "$config_path")
dest_user=$(yq e '.archive.destination.credentials.user' "$config_path")

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

# Archive the downloaded files and read output
"$current_dir/archive_data.sh" "$src_dir" "$dest_dir" "$dest_host" "$dest_user" "$bwlimit" | while IFS=, read -r event_id filename path; do

    # Check if variables are empty and log a warning if so
    if [ -z "$event_id" ] || [ -z "$filename" ] || [ -z "$path" ]; then
        log "Warning: One of the variables is empty. Event ID: '$event_id', Filename: '$filename', Path: '$path'"
    fi

    # Use jq to create a JSON payload
    json_payload=$(jq -n \
        --arg eid "$event_id" \
        --arg fn "$filename" \
        --arg pth "$path" \
        '{event_id: $eid, filename: $fn, path: $pth}')

    # Publish the event ID to the MQTT broker
    "$current_dir/mqtt_pub.sh" "$mqtt_broker" "$mqtt_port" "$mqtt_topic" "$json_payload"
done
