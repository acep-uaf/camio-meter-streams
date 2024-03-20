#!/bin/bash

####################################################
# This file downloads missing files for the event
#
#####################################################
# This script is called from check_missing.sh 
# and accepts 5 arguments:
# 
#####################################################

# Define expected filename patterns: PREFIX_eventid.EXTENSION
declare -A file_patterns
file_patterns=(["CEV"]=".CEV" ["HR"]=".CFG .DAT .HDR .ZDAT")

FULL_PATH_EVENT_DIR=$1
EVENT_ID=$2
meter_id=$3
meter_type=$4
download_progress_dir=$5

# FUNCTIONS 
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
            return 0
        fi
    done < <(tail -n +3 "$chistory_file") # Skip header lines

    echo "Timestamp for event ID $event_id not found."
    return 1
}


# Function to mark an event as in progress
# TODO: might delete this function
mark_as_in_progress() {
    touch "$download_progress_dir/in_progress/$event_id"
}

# Function to mark an event as completed
mark_as_completed() {
    mv "$download_progress_dir/in_progress/$event_id" "$download_progress_dir/completed/$event_id"
}
###############################################################################################

# Loop through the file patterns array
for prefix in "${!file_patterns[@]}"; do

    # Split the extensions for the current prefix
    IFS=' ' read -r -a extensions <<<"${file_patterns[$prefix]}"

    for extension in "${extensions[@]}"; do
        # Construct the expected filename
        expected_file_path="${FULL_PATH_EVENT_DIR}/${prefix}_${EVENT_ID}${extension}"

        # Check if the file exists
        if [ ! -f "$expected_file_path" ]; then
            missing_file=${prefix}_${EVENT_ID}${extension}
            echo "Downloading missing file: $missing_file"

            # Start an lftp session to download the missing file
            lftp -u "$USERNAME,$PASSWORD" "$METER_IP" <<EOF
            
            set xfer:clobber on
            cd $REMOTE_METER_PATH
            lcd $FULL_PATH_EVENT_DIR
            mget $missing_file
            bye
EOF
        # Check the exit status of the lftp command
        if [ $? -eq 0 ]; then
            echo "Downloaded missing file: $missing_file"
            mark_as_completed
        else
            echo "Failed to download missing file: $missing_file" "err"
        fi
  
        # Check if the file was successfully downloaded
        if [ -f "$expected_file_path" ] && [ -s "$expected_file_path" ]; then
            # grab timestamp from meter (CHISTORY.txt)
            meter_download_timestamp=$(get_event_timestamp "$event_id" "$output_dir")

            if [ -n "$meter_download_timestamp"]; then
                # Proceed to create metadata with the extracted timestamp
                otdev_download_timestamp=$(date --iso-8601=seconds)
                source "$current_dir/generate_event_metadata.sh" "$expected_file_path" "$FULL_PATH_EVENT_DIR" "$meter_id" "$meter_type" "$meter_download_timestamp" "$otdev_download_timestamp"
            else
                echo "Could not extract timestamp for event_id: $event_id"
            fi
        else
            echo "Failed to download $expected_file_path" "err"
        fi
    fi
    done
done
