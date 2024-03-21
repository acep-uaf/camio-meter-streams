#!/bin/bash

####################################################
# This file downloads missing files in event id dir
#
#####################################################
# This script is called from update_event_files.sh 
# and accepts 2 arguments:
# 1. full path to the local event_id directory
# 2. event_id
#
# download_missing_files.sh is focused on:
#
# Downloading the specified missing files.
# Updating the download progress status.
#####################################################

# Check if exactly four arguments are provided
if [ "$#" -ne 7 ]; then
    echo "Usage: $0 <full_path_event_dir> <event_id> <meter_id> <meter_type> <download_progress_dir> <meter_ip> <output_dir>" 
    exit 1
fi

# Define expected filename patterns: PREFIX_eventid.EXTENSION
declare -A file_patterns
file_patterns=(["CEV"]=".CEV" ["HR"]=".CFG .DAT .HDR .ZDAT")

FULL_PATH_EVENT_DIR=$1
EVENT_ID=$2
meter_id=$3
meter_type=$4
download_progress_dir=$5
meter_ip=$6
output_dir=$7
REMOTE_METER_PATH="EVENTS"


# FUNCTIONS 
#######################################################################################

# Function to mark an event as in progress
mark_as_in_progress() {
    local event_id=$1
    touch "$download_progress_dir/in_progress/$event_id"
}

# Function to mark an event as completed
mark_as_completed() {
    local event_id=$1
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
            lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
            set xfer:clobber on
            cd $REMOTE_METER_PATH
            lcd $FULL_PATH_EVENT_DIR
            mget $missing_file
            bye
EOF
            # Check the exit status of the lftp command
            if [ $? -eq 0 ]; then
                echo "Downloaded missing file: $missing_file"
                mark_as_completed "$EVENT_ID"
            else
                echo "Failed to download missing file: $missing_file" "err"
            fi
        fi

    done
done
