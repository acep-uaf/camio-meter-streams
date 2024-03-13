#!/bin/bash

#################################
#
#
#################################

# Simple CLI flag parsing
meter_ip="$1"
output_dir="$2" # Assumes LOCATION/DATA_TYPE/YYYY-MM/METER_ID

# Make dir if it doesn't exist
mkdir -p "$output_dir"

# Directory where this script is located (not the same as pwd because data_pipeline.sh is in another dir)
current_dir=$(dirname "${0}")

# Test connection to meter
source "$current_dir/test_meter_connection.sh" "$meter_ip"

# Check if test_meter_connection.sh was successful
if [ $? -ne 0 ]; then
  echo "Connection to meter at $meter_ip failed."
  exit 1
fi

# output_dir is the location where the data will be stored and CHISTORY.TXT will be downloaded to
for event_id in $($current_dir/get_events.sh "$meter_ip" "$output_dir"); do
  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"

  # Check if download_event.sh was successful before creating metadata
  if [ $? -eq 0 ]; then
    # Assuming create_metadata_json.sh and create_metadata_txt.sh take the event directory as input
    source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir"
  else
    echo "Download failed for event_id: $event_id, skipping metadata creation."
  fi

done

echo "Finished downloading events."
