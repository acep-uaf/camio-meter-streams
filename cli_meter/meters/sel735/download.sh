#!/bin/bash

#################################
# 
#
#################################


# Simple CLI flag parsing
meter_ip="$1"
output_dir="$2"

# LOCATION/DATA_TYPE/YYYY-MM/METER_ID

mkdir -p "$output_dir"

current_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)


# Test connection to meter
source "$current_dir/test_meter_connection.sh"

# Check if test_meter_connection.sh was successful
if [ $? -ne 0 ]; then
  echo "Connection to meter at $meter_ip failed."
  exit 1
fi

source "$current_dir/get_events.sh" "$meter_ip" "$output_dir"

# output_dir is the location where the data will be stored and CHISTORY.TXT will be downloaded to
#for event_id in $($current_dir/get_events.sh "$meter_ip" "$output_dir"); do 
#  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"
#done

echo "Finished downloading events."
