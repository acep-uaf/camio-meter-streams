#!/bin/bash
#################################
#
#
#################################
current_dir=$(dirname "$(readlink -f "$0")")
current_event_id=""
source "$current_dir/commons.sh"
trap handle_sigint SIGINT

# Check for exactly 4 arguments
if [ "$#" -ne 4 ]; then
  fail "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type>"
fi

# Simple CLI flag parsing
meter_ip="$1"
base_output_dir="$2/working"
base_zipped_output_dir="$2/level0"
meter_id="$3"
meter_type="$4"

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip"

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

# output_dir is the location where the data will be stored
for event_info in $($current_dir/get_events.sh "$meter_ip" "$meter_id" "$base_output_dir"); do

  # Split the output into variables
  IFS=',' read -r event_id date_dir event_timestamp <<<"$event_info"

  # Update current_event_id for mark_event_incomplete()
  current_event_id=$event_id

  # Update output_dir
  output_dir="$base_output_dir/$date_dir/$meter_id"

  # Download event directory (5 files)
  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"

  # Check if download_event.sh was successful before creating metadata
  if [ $? -eq 0 ]; then
    # Timestamp is time this script is run.
    download_timestamp=$(date --iso-8601=seconds)

    # If all files are downloaded successfully generate metadata/checksum then zip
    if validate_download "$output_dir" "$event_id"; then
      # Generate metadata and checksums of files for the event
      source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp"

      # Zip the event directory, including all files and the checksum.md5 file
      event_zipped_output_dir="$base_zipped_output_dir/$date_dir/$meter_id"
      mkdir -p "$event_zipped_output_dir"
      source "$current_dir/zip_event.sh" "$output_dir" "$event_zipped_output_dir" "$event_id"

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
else
  log "Finished downloaded with some errors."
fi
