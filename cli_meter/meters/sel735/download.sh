#!/bin/bash

#################################
# 
#
#################################

# Simple CLI flag parsing
meter_ip="$1"
output_dir="$2"

# Check if the necessary arguments are provided
if [[ -z "$meter_ip" ]] || [[ -z "$output_dir" ]]; then
  echo "Usage: $0 <meter_ip> <output_dir>"
  exit 1
fi

# Connect to the meter
./connect.sh "$meter_ip"

# Check if connect.sh was successful
if [ $? -ne 0 ]; then
  echo "Connection to meter at $meter_ip failed."
  exit 1
fi

# Get new event IDs
event_ids=$(./get_events.sh "$meter_ip")

# Check if get_events.sh was successful
if [ $? -ne 0 ]; then
  echo "Failed to retrieve event IDs."
  exit 1
fi

# Ensure the output directory exists
mkdir -p "$output_dir"

# Loop over each event_id and call download_event.sh for each
for event_id in $event_ids; do
  # Create directory for each event
  mkdir -p "$output_dir/$event_id"
  
  # Download the event
  ./download_event.sh "$meter_ip" "$event_id" "$output_dir/$event_id"
  
  # Check if download_event.sh was successful
  if [ $? -ne 0 ]; then
    echo "Failed to download event $event_id."
  else
    echo "Successfully downloaded event $event_id."
  fi
done

echo "Finished downloading events."
