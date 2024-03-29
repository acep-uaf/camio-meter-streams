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
output_dir="$2/level0" # Assumes LOCATION/DATA_TYPE/YYYY-MM/METER_ID
meter_id="$3"
meter_type="$4"

# Directory where this script is located (not the same as pwd because data_pipeline.sh is in another dir)
current_dir=$(dirname "${0}")

# Make dir if it doesn't exist
mkdir -p "$output_dir"

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip"

# Check if test_meter_connection.sh was successful
if [ $? -ne 0 ]; then
  echo "Connection to meter at $meter_ip failed."
  exit 1
fi


# FUNCTION 
#######################################################################################
# Function to extract and format the timestamp for a given event ID from CHISTORY.TXT
get_event_timestamp() {
    local event_id="$1"
    local chistory_file="$2/CHISTORY.TXT"
    local timestamp=""

    # Ensure CHISTORY.TXT exists
    if [ ! -f "$chistory_file" ]; then
        echo "CHISTORY.TXT file not found."
        return 1
    fi

    # Extract the timestamp for the given event ID
    while IFS=, read -r _ eid month day year hour min sec _; do
        if [[ "$eid" == "$event_id" ]]; then
            timestamp=$(printf '%04d-%02d-%02dT%02d:%02d:%02d' "$year" "$month" "$day" "$hour" "$min" "$sec")
            echo "$timestamp"
            return 0
        fi
    done < <(tail -n +3 "$chistory_file") # Skip header lines

    echo "Timestamp for event ID $event_id not found."
    return 1
}
###############################################################################################


# output_dir is the location where the data will be stored
for event_info in $($current_dir/get_events.sh "$meter_ip" "$meter_id" "$output_dir"); do

  # Split the output into event_id and formatted_date
  IFS=',' read -r event_id date_dir <<< "$event_info"
  log "event_id: $event_id, date_dir: $date_dir"

  # Update current_event_id for the cleanup function
  current_event_id=$event_id 

  # Update output_dir and download event
  output_dir="$output_dir/$date_dir/$meter_id"
  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"

  # Check if download_event.sh was successful before creating metadata
  if [ $? -eq 0 ]; then
    # grab timestamp from meter (CHISTORY.txt)
    meter_download_timestamp=$(get_event_timestamp "$event_id" "$output_dir")

    if [ -n "$meter_download_timestamp" ]; then
      # Proceed to create metadata with the extracted timestamp
      otdev_download_timestamp=$(date --iso-8601=seconds)
      source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$meter_download_timestamp" "$otdev_download_timestamp"
    else
      echo "Could not extract timestamp for event_id: $event_id"
    fi
  else
    echo "Download failed for event_id: $event_id, skipping metadata creation."
  fi

done

echo "Finished downloading events."
