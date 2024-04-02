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


# output_dir is the location where the data will be stored
for event_info in $($current_dir/get_events.sh "$meter_ip" "$meter_id" "$base_output_dir"); do

  # Split the output into event_id and formatted_date
  IFS=',' read -r event_id date_dir <<< "$event_info"

  # Update current_event_id for the cleanup function
  current_event_id=$event_id 

  # Update output_dir and download event
  output_dir="$base_output_dir/$date_dir/$meter_id"

  # download_event downloads 5 files for each event 
  source "$current_dir/download_event.sh" "$meter_ip" "$event_id" "$output_dir"

  # Check if download_event.sh was successful before creating metadata
  if [ $? -eq 0 ]; then
    # grab timestamp from meter (CHISTORY.txt)
    meter_download_timestamp=$(get_event_timestamp "$event_id" "$output_dir")

    if [ -n "$meter_download_timestamp" ]; then
      # Proceed to create metadata with the extracted timestamp
      # this timestamp is for when we run the download script, not when the event occurred
      otdev_download_timestamp=$(date --iso-8601=seconds)

      #check if all files are downloaded before generating metadata/checksum/zip
      # if validate_download is true zip event dir 
      if validate_download "$output_dir" "$event_id"; then
        echo "All files downloaded for event_id: $event_id"

        # Generate metadata for the event
        source "$current_dir/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$meter_download_timestamp" "$otdev_download_timestamp"
        
        # Generate MD5 checksums for all files in the event directory, including the metadata file
        md5sum $output_dir/* > $output_dir/$event_id/checksum.md5
        echo "Checksum for event directory $event_id generated."

        # Proceed to zip the event directory, including all files and the checksum.md5 file
        zip -r -q "$output_dir/${event_id}.zip" "$output_dir/$event_id"
        echo "Event directory $event_id zipped, including checksum."

      else
        echo "Not all files downloaded for event_id: $event_id"
        #TODO: handle this case
      fi
    else
      echo "Could not extract timestamp for event_id: $event_id"
    fi
  else
    echo "Download failed for event_id: $event_id, skipping metadata creation."
  fi

done

echo "Finished downloading events."
