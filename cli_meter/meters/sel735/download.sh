#!/bin/bash
# ==============================================================================
# Script Name:        download.sh
# Description:        This script orchestrates the process of downloading event
#                     files from the SEL-735 meter, validating them, generating
#                     metadata, and zipping the files.
#
# Usage:              ./download.sh <meter_ip> <output_dir> <meter_id> <meter_type>
#                     <bw_limit> <data_type> <location>
# Called by:          data_pipeline.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   output_dir        Base directory where the event data will be stored
#   meter_id          Meter ID
#   meter_type        Meter Type (ex. sel735)
#   bw_limit          Bandwidth limit for the download process
#
# Requirements:       commons.sh, test_meter_connection.sh, get_events.sh,
#                     download_event.sh, generate_event_metadata.sh, zip_event.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/commons.sh"
export current_event_id=""

trap handle_sigint SIGINT

# Check for exactly 7 arguments
if [ "$#" -ne 7 ]; then
  fail $EXIT_UNKNOWN "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type> <bw_limit> <data_type> <location>"
fi

# Simple CLI flag parsing
meter_ip="$1"
base_output_dir="$2/working"
base_zipped_output_dir="$2/level0"
meter_id="$3"
meter_type="$4"
bw_limit="$5"
data_type="$6"
location="$7"

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
if ! source "$current_dir/test_meter_connection.sh" "$meter_ip" "$bw_limit"; then
  fail $EXIT_UNKNOWN "Failed to connect to meter: $meter_ip"
fi

# output_dir is the location where the data will be stored
for event_info in $($current_dir/get_events.sh "$meter_ip" "$meter_id" "$base_output_dir"); do

  # Split the output into variables
  IFS=',' read -r event_id date_dir event_timestamp <<<"$event_info"

  # Update current_event_id for mark_event_incomplete()
  current_event_id=$event_id

  # Update output_dir
  output_dir="$base_output_dir/$date_dir/$meter_id"
  path="$location/$data_type/$date_dir/$meter_id"

  # Download event directory (5 files)
  if ! source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir" "$bw_limit"; then
    fail $EXIT_UNKNOWN "Download failed for event_id: $event_id"
  fi

   # If all files are downloaded successfully generate metadata/checksum then zip
  if validate_download "$output_dir" "$event_id"; then
    # Get the current timestamp for the download
    download_timestamp=$(date --iso-8601=seconds)
    
    # If all files are downloaded successfully, generate metadata/checksum then zip
    if ! source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp"; then
      fail $EXIT_UNKNOWN "Metadata generation failed for event: $event_id"
    fi
    
    # Zip the event directory, including all files and the checksum.md5 file
    event_zipped_output_dir="$base_zipped_output_dir/$date_dir/$meter_id"
    mkdir -p "$event_zipped_output_dir"

    if ! source "$current_dir/zip_event.sh" "$output_dir" "$event_zipped_output_dir" "$event_id"; then
      fail $EXIT_UNKNOWN "Zipping failed for event: $event_id"
    fi

    zip_filename="${event_id}.zip"
      
    # Call the create_message.sh script
    if ! source "$current_dir/create_message.sh" "$event_id" "$zip_filename" "$path" "$data_type" "$event_zipped_output_dir"; then
      log "WARNING: Message creation failed for event: $event_id"
    fi

  else
    fail $EXIT_UNKNOWN "Not all files downloaded for event: $event_id"
  fi
done

exit $EXIT_SUCCESS
