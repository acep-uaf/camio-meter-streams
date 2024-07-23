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

# output_dir is the location where the data will be stored
for event_info in $events; do
  IFS=',' read -r event_id date_dir event_timestamp <<<"$event_info"
  log "Processing event: $event_id"

  # Update current_event_id for mark_event_incomplete
  current_event_id=$event_id

  # Update output_dir
  output_dir="$base_output_dir/$date_dir/$meter_id"
  path="$location/$data_type/$date_dir/$meter_id"

  download_start=$(date -u --iso-8601=seconds)

  # Download event directory (5 files)
  if "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir" "$bandwidth_limit"; then
    event_status="success"
  else
    mark_event_incomplete
    event_status="failure"
    error_message="Failed to download event files for event_id: $event_id"
    error_code=$STREAMS_DOWNLOAD_FAIL
    warning "$error_message" $error_code
  fi

  # Append event information after processing
  append_event "$YAML_SUMMARY_FILE" "$meter_id" "$event_id" "$event_status" "$error_message" "$error_code"

  download_end=$(date -u --iso-8601=seconds)
  
  # Validate the downloaded files
  validate_download "$output_dir/$event_id" "$event_id" && log "Downloaded files validated for event: $event_id" || {
    log "Not all files downloaded for event: $event_id"
    mark_event_incomplete "$event_id" "$output_dir"
    continue
  }

  # Generate metadata for the event
  "$current_dir/generate_metadata_yml.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_start" "$download_end" || {
    mark_event_incomplete
    failure $STREAMS_METADATA_FAIL "Failed to generate metadata"
  }

  # Validate the metadata files
  validate_complete_directory "$output_dir/$event_id" "$event_id" && log "Metadata files validated for event: $event_id" || {
    mark_event_incomplete
    failure $STREAMS_INCOMPLETE_DIR "Missing metadata file in event directory"
  }

  # Zip the event directory, including all files and the checksum.md5 file
  event_zipped_output_dir="$base_zipped_output_dir/$date_dir/$meter_id"
  mkdir -p "$event_zipped_output_dir" 

  # LOCATION-TYPE-METER_ID-YYYYMM-EVENT_ID
  zip_filedate="${date_dir//-/}"
  zip_filename="$location-$data_type-$meter_id-$zip_filedate-$event_id.zip"

  # Zip the event files and empty the working event directory
  "$current_dir/zip_event.sh" "$output_dir" "$event_zipped_output_dir" "$event_id" "$zip_filename"|| {
    mark_event_incomplete
    failure $STREAMS_ZIP_FAIL "Failed to zip event files"
  }

  # Create the message file (JSON) for the event
  "$current_dir/create_message.sh" "$event_id" "$zip_filename" "$path" "$data_type" "$event_zipped_output_dir" || {
    mark_event_incomplete
    warning "Failed to create message file" $STREAMS_FILE_CREATION_FAIL
  }

done
