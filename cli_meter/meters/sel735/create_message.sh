#!/bin/bash
# ==============================================================================
# Script Name:        create_message.sh
# Description:        This script creates a .message file with a JSON payload.
#
# Usage:              ./create_message.sh <event_id> <zip_filename> <md5sum_value>
#                     <data_type> <output_dir>
#
# Arguments:
#   meter_id          Meter ID
#   event_id          event ID
#   zip_filename      Name of the zipped file
#   md5sum_value      md5sum of the zipped file
#   data_type         Type of data
#   output_dir        Directory where the message file will be stored
#
# Requirements:       jq
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh" 

# Check for exactly 6 arguments
[ "$#" -ne 6 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_id> <event_id> <zip_filename> <md5sum_value> <data_type> <output_dir>"

meter_id="$1"
event_id="$2"
zip_filename="$3"
md5sum_value="$4"
data_type="$5"
output_dir="$6"
message_file="$output_dir/${zip_filename}.message"

# Create the JSON payload
json_payload=$(jq -n \
    --arg mid "$meter_id" \
    --arg eid "$event_id" \
    --arg fn "$zip_filename" \
    --arg md5s "$md5sum_value" \
    --arg dt "$data_type" \
    '{meter_id: $mid, event_id: $eid, filename: $fn, md5sum: $md5s, data_type: $dt}')

# Write the JSON payload to the .message file
echo "$json_payload" > "$message_file" && log "Created message file: $message_file" || failure $STREAMS_FILE_CREATION_FAIL "Failed to write to message file: $message_file"

