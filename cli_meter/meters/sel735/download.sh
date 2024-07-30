#!/bin/bash
# ==============================================================================
# Script Name:        download.sh
# Description:        This script orchestrates the process of downloading event
#                     files from the SEL-735 meter, validating them, generating
#                     metadata, and zipping the files.
#
# Usage:              ./download.sh <meter_ip> <output_dir> <meter_id> <meter_type>
#                     <bandwidth_limit> <data_type> <location> <max_age_days> <max_retries>
# Called by:          data_pipeline.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   output_dir        Base directory where the event data will be stored
#   meter_id          Meter ID
#   meter_type        Meter Type (ex. sel735)
#   bandwidth_limit   Bandwidth limit for the connection
#   data_type         Data type (ex. power)
#   location          Location of the meter
#   max_age_days      Maximum age of the event in days
#   max_retries       Maximum number of retries for the connection
#
# Requirements:       common_sel735.sh, test_meter_connection.sh, get_events.sh,
#                     download_event.sh, generate_event_metadata.sh, zip_event.sh
#                     create_message.sh
# ==============================================================================
handle_fail() {
  local event_id=$1
  local output_dir=$2
  local error_code=$3
  local error_message=$4
  local meter_id=$5
  local download_start=$6
  local download_end=$7
  local download_size=$(get_total_event_files_size "$output_dir/$event_id" "$event_id")

  mark_event_incomplete "$event_id" "$output_dir"
  warning "$error_code" "$error_message"
  append_event "$meter_id" "$event_id" "failure" "$download_start" "$download_end" "$download_size" "$error_code" "$error_message"
}

current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"
source "$current_dir/../../yaml_summary.sh"
source "$current_dir/common_sel735.sh"
export current_event_id=""

# Trap the signals and associate them with the handler function
trap 'handle_sig SIGINT' SIGINT
trap 'handle_sig SIGQUIT' SIGQUIT
trap 'handle_sig SIGTERM' SIGTERM

# Check for exactly 9 arguments
[ "$#" -ne 9 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_ip> <output_dir> <meter_id> <meter_type> <bw_limit> <data_type> <location> <max_age_days> <max_retries>"

# Simple CLI flag parsing
meter_ip="$1"
base_output_dir="$2/working"
base_zipped_output_dir="$2/level0"
meter_id="$3"
meter_type="$4"
bandwidth_limit="$5"
data_type="$6"
location="$7"
max_age_days="$8"
max_retries="$9"

log "Starting download process for meter: $meter_id"

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip" "$bandwidth_limit" "$max_retries" || failure $STREAMS_CONNECTION_FAIL "Failed to connect to meter"

# Capture the output of get_events.sh
events=$("$current_dir/get_events.sh" "$meter_ip" "$meter_id" "$base_output_dir" "$max_age_days")

# Check if there are any events to download
[ -z "$events" ] && log "No new events to download for meter: $meter_id" && exit 0

total_events=$(echo "$events" | wc -l)

init_event_summary "$meter_id" $total_events

# output_dir is the location where the data will be stored
for event_info in $events; do
  IFS=',' read -r event_id date_dir event_timestamp <<<"$event_info"
  log "Processing event: $event_id"

  # Update current_event_id for mark_event_incomplete
  current_event_id=$event_id
  event_status=""

  # Update output_dir
  output_dir="$base_output_dir/$date_dir/$meter_id"
  path="$location/$data_type/$date_dir/$meter_id"

  download_start=$(date -u --iso-8601=seconds)

  # Download event directory (5 files)
  if "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir" "$bandwidth_limit"; then
    event_status="success"
    download_end=$(date -u --iso-8601=seconds)
    download_size=$(get_total_event_files_size "$output_dir/$event_id" "$event_id")
  else
    download_end=$(date -u --iso-8601=seconds)
    handle_fail "$event_id" "$output_dir" "$STREAMS_DOWNLOAD_FAIL" "Failed to download event files for event_id: $event_id" "$meter_id" "$download_start" "$download_end"
    continue
  fi
  
  # Validate the downloaded files
  validate_download "$output_dir/$event_id" "$event_id" && log "Downloaded files validated for event: $event_id" || {
    handle_fail "$event_id" "$output_dir" "$STREAMS_UNKNOWN" "Failed to validate event files for event: $event_id"  "$meter_id" "$download_start" "$download_end"
    continue
  }

  # Generate metadata for the event
  "$current_dir/generate_metadata_yml.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_start" "$download_end" || {
    handle_fail "$event_id" "$output_dir" "$STREAMS_METADATA_FAIL" "Failed to generate metadata for event: $event_id"  "$meter_id" "$download_start" "$download_end"
    continue
  }

  # Validate the metadata files
  validate_complete_directory "$output_dir/$event_id" "$event_id" && log "Metadata files validated for event: $event_id" || {
    handle_fail "$event_id" "$output_dir" "$STREAMS_INCOMPLETE_DIR" "Missing metadata file in event directory for event_id: $event_id" "$meter_id" "$download_start" "$download_end"
    continue
  }

  # Zip the event directory, including all files and the checksum.md5 file
  event_zipped_output_dir="$base_zipped_output_dir/$date_dir/$meter_id"
  mkdir -p "$event_zipped_output_dir" 

  # LOCATION-TYPE-METER_ID-YYYYMM-EVENT_ID
  zip_filedate="${date_dir//-/}"
  zip_filename="$location-$data_type-$meter_id-$zip_filedate-$event_id.zip"

  # Zip the event files and empty the working event directory
  "$current_dir/zip_event.sh" "$output_dir" "$event_zipped_output_dir" "$event_id" "$zip_filename"|| {
    handle_fail "$event_id" "$output_dir" "$STREAMS_ZIP_FAIL" "Failed to zip event: $event_id" "$meter_id" "$download_start" "$download_end"
    continue
  }

  # Create the message file (JSON) for the event
  "$current_dir/create_message.sh" "$event_id" "$zip_filename" "$path" "$data_type" "$event_zipped_output_dir" || {
    handle_fail "$event_id" "$output_dir" "$STREAMS_FILE_CREATION_FAIL" "Failed to create message file for event: $event_id"  "$meter_id" "$download_start" "$download_end" 
    continue
  }

  append_event $meter_id $event_id "$event_status" "$download_start" "$download_end" "$download_size"
done
