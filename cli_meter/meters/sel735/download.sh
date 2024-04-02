#!/bin/bash

#################################
#
#
#################################

# Check for exactly 4 arguments
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type>"
  exit 1
fi

# Simple CLI flag parsing
meter_ip="$1"
base_output_dir="$2/level0" # Assumes LOCATION/DATA_TYPE/YYYY-MM/METER_ID
meter_id="$3"
meter_type="$4"

# Directory where this script is located (not the same as pwd because data_pipeline.sh is in another dir)
current_dir=$(dirname "${0}")

# Make dir if it doesn't exist
mkdir -p "$base_output_dir"

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip"

# Check if test_meter_connection.sh was successful
if [ $? -ne 0 ]; then
  echo "Connection to meter at $meter_ip failed."
  exit 1
fi

###############################################################################################
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

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

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

  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"

  # Check if download_event.sh was successful before creating metadata
  if [ $? -eq 0 ]; then
    # Timestamp is time this script is run.
    download_timestamp=$(date --iso-8601=seconds)

    #check if all files are downloaded before generating metadata
    # if validate_download is true zip event dir
    if validate_download "$output_dir" "$event_id"; then
      source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$event_timestamp" "$download_timestamp"
      #TODO: create zip_event.sh
      #source "$current_dir/zip_event.sh" "$output_dir" "$event_id"
    else
      #TODO: handle this case
      echo "Not all files downloaded for event_id: $event_id"
      log "Not all files downloaded for event: $event_id" "warn"
      loop_success=false
    fi

  else
    echo "Download failed for event_id: $event_id, skipping metadata creation."
    log "Download failed for event_id: $event_id, skipping metadata creation." "warn"
    loop_success=false
  fi

done

# After the loop, check the flag and log accordingly
if [ "$loop_success" = true ]; then
  echo "Successfully downloaded all events."
  log "Successfully downloaded all events."
else
  echo "Finished downloaded with some errors. Check logs for more information."
  log "Finished downloaded with some errors." "err"
fi
