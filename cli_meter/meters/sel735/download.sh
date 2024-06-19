#!/bin/bash
# ==============================================================================
# Script Name:        download.sh
# Description:        This script orchestrates the process of downloading event
#                     files from the SEL-735 meter, validating them, generating
#                     metadata, and zipping the files.
#
# Usage:              ./download.sh <meter_ip> <output_dir> <meter_id> <meter_type>
#                     <bandwidth_limit> <data_type> <location>
# Called by:          data_pipeline.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   output_dir        Base directory where the event data will be stored
#   meter_id          Meter ID
#   meter_type        Meter Type (ex. sel735)
#   bandwidth_limit   Bandwidth limit for the download process
#
# Requirements:       commons.sh, test_meter_connection.sh, get_events.sh,
#                     download_event.sh, generate_event_metadata.sh, zip_event.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"
export current_event_id=""

trap handle_sigint SIGINT

# Check for exactly 4 arguments
if [ "$#" -ne 7 ]; then
  fail "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type> <bandwidth_limit> <data_type> <location>"
fi

# Simple CLI flag parsing
meter_ip="$1"
base_output_dir="$2/working"
base_zipped_output_dir="$2/level0"
meter_id="$3"
meter_type="$4"
bandwidth_limit="$5"
data_type="$6"
location="$7"

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
if ! source "$current_dir/test_meter_connection.sh" "$meter_ip" "$bandwidth_limit"; then
  fail "Connection to meter $meter_ip failed"
  exit 1
fi

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

# Call get_events.sh and check its exit status
events_list=$($current_dir/get_events.sh "$meter_ip" "$meter_id" "$base_output_dir")
if [ $? -ne 0 ]; then
  fail "Failed to retrieve events for meter: $meter_id"
  exit 1
fi

# output_dir is the location where the data will be stored
echo "$events_list" | while IFS=, read -r event_id date_dir event_timestamp; do
  log "Processing event info: $event_id, $date_dir, $event_timestamp"

  # Update current_event_id for mark_event_incomplete()
  current_event_id=$event_id

  # Update output_dir
  output_dir="$base_output_dir/$date_dir/$meter_id"
  path="$location/$data_type/$date_dir/$meter_id"

  # Download event directory (5 files)
  if ! source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir" "$bandwidth_limit"; then
    log "Download failed for event_id: $event_id, skipping metadata creation."
    loop_success=false
    continue
  fi

  # Check if download_event.sh was successful before creating metadata
  if validate_download "$output_dir" "$event_id"; then
    log "Download validated successfully for event_id: $event_id"

    # Timestamp is time this script is run.
    download_timestamp=$(date --iso-8601=seconds)
    log "Download timestamp: $download_timestamp"

    # If all files are downloaded successfully generate metadata/checksum then zip
    if source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp"; then
      log "Metadata generated successfully for event_id: $event_id"

      # Zip the event directory, including all files and the checksum.md5 file
      event_zipped_output_dir="$base_zipped_output_dir/$date_dir/$meter_id"

      mkdir -p "$event_zipped_output_dir"
      source "$current_dir/zip_event.sh" "$output_dir" "$event_zipped_output_dir" "$event_id"

      zip_filename="${event_id}.zip"
      
      # Call the create_message.sh script
      source "$current_dir/create_message.sh" "$event_id" "$zip_filename" "$path" "$data_type" "$event_zipped_output_dir"

    else
      #TODO: handle this case
      log "Not all files downloaded for event: $event_id"
      loop_success=false
    fi
  else
    log "Download failed for event_id: $event_id, skipping metadata creation."
    loop_success=false
  fi
done

# After the loop, check the flag and log accordingly
if [ "$loop_success" = true ]; then
  log "Successfully downloaded all events."
  exit 0
else
  log "Finished downloading with some errors."
  exit 1
fi
