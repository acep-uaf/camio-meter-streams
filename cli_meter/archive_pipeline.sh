#!/bin/bash

# Use rsync to move data from local machine to DAS (Data Acquisition System) and publish message to MQTT broker

# Define the current directory
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"

# To be optionally be overriden by flags
config_path=""
# Function to display help
show_help() {
    log "Usage: $0 [options]"
    log ""
    log "Options:"
    log "  -c, --config <path>    Specify the path to the config file."
    log "  -h, --help             Display this help message and exit."
    log ""
    log "Examples:"
    log "  $0 -c /path/to/config.yaml"
    log "  $0 --config /path/to/config.yaml"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--config)
            config_path="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log "Unknown parameter passed: $1"
            show_help
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

