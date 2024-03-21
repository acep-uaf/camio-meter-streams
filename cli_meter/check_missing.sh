#!/bin/bash

###############################################################
# check_missing.sh handles:
#
# Checking for in-progress for incomplete downloads.
# Calling download_missing_files.sh to redownload these files.
# Using get_event_timestamp to get timestamps for events.
# Generating metadata once the downloads are confirmed.
#
# TODO: add in notes to match what other scripts look like
###############################################################

# Check if exact arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <meter_ip> <output_dir> <meter_id> <meter_type> <meter_ip>" 
    exit 1
fi

# Assign arguments to variables
meter_ip=$1
output_dir=$2
meter_id=$3
meter_type=$4
download_progress_dir="$output_dir/.download_progress"
event_dir_path="$output_dir/level0"

echo "CALLING CHECK_MISSING.SH"

# Function to mark an event as completed
mark_as_completed() {
    local event_id=$1
    mv "$download_progress_dir/in_progress/$event_id" "$download_progress_dir/completed/$event_id"
}

# Function to check if all files for an event have been downloaded
all_files_downloaded() {
    local event_dir=$1
    local event_id=$2
    # Assuming these are the files you expect to have downloaded
    local expected_files=("CEV_${event_id}.CEV" "HR_${event_id}.CFG" "HR_${event_id}.DAT" "HR_${event_id}.HDR" "HR_${event_id}.ZDAT")
    for file in "${expected_files[@]}"; do
        if [ ! -f "${event_dir}/${file}" ]; then
            return 1 # File is missing
        fi
    done
    return 0 # All files are present
}

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

# Check for events marked as in progress but not completed
if [ -d "$download_progress_dir/in_progress" ]; then
    for in_progress_event in "$download_progress_dir/in_progress/"*; do
        event_id=$(basename "$in_progress_event")
        event_path="$event_dir_path/$event_id"

        echo "Attempting to redownload event: $event_id due to incomplete download."

        # Execute download script for the specific event
        source "meters/$meter_type/download_missing_file.sh" "$event_path" "$event_id" "$meter_ip"

        # After attempting to redownload, check if all files are present
        if all_files_downloaded "$event_path" "$event_id"; then

            meter_download_timestamp=$(get_event_timestamp "$event_id" "$output_dir")
            echo "timestamp from meter: $meter_download_timestamp"
            otdev_download_timestamp=$(date --iso-8601=seconds)

            # Call the metadata generation script if all files have been downloaded
            echo "METADATA PASS IN event path as 1st arg $event_path"
            source "meters/$meter_type/generate_event_metadata.sh" "$event_id" "$output_dir" "$meter_id" "$meter_type" "$meter_download_timestamp" "$otdev_download_timestamp"
            # Check if metadata was successfully created

            mark_as_completed "$event_id"

            if [ $? -eq 0 ]; then
                echo "Metadata created for event: $event_id"
            else
                echo "Failed to create metadata for event: $event_id"
            fi
        else
            echo "Not all files have been downloaded for event: $event_id"
        fi
    done
else
    echo "No in-progress downloads found to check or redownload."
fi