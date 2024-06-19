#!/bin/bash
# ==============================================================================
# Script Name:        create_message.sh
# Description:        This script creates a .message file with a JSON payload.
#
# Usage:              ./create_message.sh <event_id> <zip_filename> <path>
#                     <data_type> <output_dir>
#
# Arguments:
#   id                ID
#   zip_filename      Name of the zipped file
#   path              Path to file
#   data_type         Type of data
#   output_dir        Directory where the message file will be stored
# ==============================================================================

# Check for exactly 5 arguments
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <event_id> <zip_filename> <path> <data_type> <output_dir>"
  exit 1
fi

event_id="$1"
zip_filename="$2"
path="$3"
data_type="$4"
output_dir="$5"
message_file="$output_dir/${zip_filename}.message"

# Create the JSON payload
json_payload=$(jq -n \
    --arg id "$event_id" \
    --arg fn "$zip_filename" \
    --arg pth "$path" \
    --arg dt "$data_type" \
    '{id: $id, filename: $fn, path: $pth, data_type: $dt}')

# Write the JSON payload to the .message file
echo "$json_payload" > "$message_file"
if [ $? -eq 0 ]; then
    echo "Created message file: $message_file with payload: $json_payload"
else
    echo "Failed to write to message file: $message_file" >&2
    exit 1
fi
