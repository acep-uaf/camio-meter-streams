#!/bin/bash
#################################
#
#
#################################

########### FUNCTIONS ##########################################################################
handle_sigint() {
  # Mark event incomplete if event_id is set
  if [ -n "$current_event_id" ]; then
    local output_dir="$base_output_dir/$date_dir/$meter_id"
    mark_event_incomplete "$current_event_id" "$output_dir"
  else
    log "current_event_id is not set, no event to move to .incomplete."
  fi

  fail "Operating interupted by SIGINT, exiting..."
}

# Mark event as incomplete
mark_event_incomplete() {
  log "Marking event as incomplete..."
  local event_id="$1"
  local original_dir="$2/$event_id"
  local incomplete_dir="$original_dir.incomplete_$(date -u +"%Y-%m-%dT%H:%M:%S")"

  # Check if the original directory exists
  if [ -d "$original_dir" ]; then
    mv "$original_dir" "$incomplete_dir"
    log "Moved event $event_id to .incomplete"
  else
    echo "Error: Directory $original_dir does not exist."
  fi
}

# Function to check if all files for an event have been downloaded
validate_download() {
  local event_dir=$1
  local event_id=$2
  # Assuming these are the files you expect to have downloaded
  local expected_files=("CEV_${event_id}.CEV" "HR_${event_id}.CFG" "HR_${event_id}.DAT" "HR_${event_id}.HDR" "HR_${event_id}.ZDAT")
  for file in "${expected_files[@]}"; do
    if [ ! -f "${event_dir}/${file}" ]; then
      return 0 # File is missing
    fi
  done
  return 1 # All files are present
}
###############################################################################################

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

current_dir=$(dirname "$(readlink -f "$0")")
current_event_id=""

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip"

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

# output_dir is the location where the data will be stored
for event_info in $($current_dir/get_events.sh "$meter_ip" "$meter_id" "$base_output_dir"); do
  # Split the output into event_id and formatted_date
  IFS=',' read -r event_id date_dir event_timestamp <<<"$event_info"

  # Update current_event_id for the cleanup function
  current_event_id=$event_id

  # Update output_dir and download event
  output_dir="$base_output_dir/$date_dir/$meter_id"

  # download_event downloads 5 files for each event
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
