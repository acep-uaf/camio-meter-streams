#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System) and publish message to MQTT broker

# Define the current directory
current_dir=$(dirname "$(readlink -f "$0")")
echo $current_dir
source "$current_dir/commons.sh"

# To be optionally be overriden by flags
config_path=""

# Parse command line arguments for --config/-c
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --config | -c)
        config_path="$2"
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

# Parse configuration using yq
source_dir=$(yq e '.archive.source_directory' $config_path)
destination_dir=$(yq e '.archive.destination_directory' $config_path)
mqtt_broker=$(yq e '.mqtt.host' $config_path)
mqtt_port=$(yq e '.mqtt.port' $config_path) # If you need to use the port
mqtt_topic=$(yq e '.mqtt.topic' $config_path)

# Archive the downloaded files
$current_dir/archive_data.sh "$source_dir" "$destination_dir" | while IFS= read -r event_id; do
    # Publish the event ID to the MQTT broker
    "$current_dir/mqtt_pub.sh" "$mqtt_broker" "$mqtt_port" "$mqtt_topic" "$event_id"
done

