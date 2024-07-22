#!/bin/bash
# ==============================================================================
# Script Name:        create_message.sh
# Description:        This script creates a .message file with a JSON payload.
#
# Usage:              ./create_message.sh <event_id> <zip_filename> <path>
#                     <data_type> <output_dir>
#
# Arguments:
#   event_id          event ID
#   zip_filename      Name of the zipped file
#   path              Path to file
#   data_type         Type of data
#   output_dir        Directory where the message file will be stored
#
# Requirements:       jq
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh" 

# Check for exactly 5 arguments
[ "$#" -ne 5 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <event_id> <zip_filename> <path> <data_type> <output_dir>"

event_id="$1"
zip_filename="$2"
path="$3"
data_type="$4"
output_dir="$5"
message_file="$output_dir/${zip_filename}.message"

# Create the JSON payload
json_payload=$(jq -n \
    --arg eid "$event_id" \
    --arg fn "$zip_filename" \
    --arg pth "$path" \
    --arg dt "$data_type" \
    '{event_id: $eid, filename: $fn, path: $pth, data_type: $dt}')

# Write the JSON payload to the .message file
echo "$json_payload" > "$message_file" && log "Created message file: $message_file" || warning "Failed to write to message file: $message_file"

