#!/bin/bash
# ==============================================================================
# Script Name:        get_events.sh
# Description:        This script returns a list of event IDs that need to be
#                     downloaded by checking the CHISTORY.TXT file on the meter.
#
# Usage:              ./get_events.sh <meter_ip> <meter_id> <output_dir>
# Called by:          download.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   meter_id          Meter ID
#   output_dir        Base directory where the event data will be stored
#
# Requirements:       lftp
# ==============================================================================

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    fail "Usage: $0 <meter_ip> <meter_id> <output_dir>"
fi

meter_ip=$1
meter_id=$2
output_dir=$3

files_per_event=7
remote_filename="CHISTORY.TXT"
remote_dir="EVENTS"
temp_dir_path="temp_dir.XXXXXX"

# Create a temporary directory to store the CHISTORY.TXT file
temp_dir=$(mktemp --tmpdir -d $temp_dir_path)

# Remove temporary directory on exit
trap 'rm -rf "$temp_dir"' EXIT

# Connect to meter and get CHISTORY.TXT
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<END_FTP_SESSION
set xfer:clobber on
cd $remote_dir
lcd $temp_dir
mget $remote_filename
bye
END_FTP_SESSION

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session successful for: $(basename "$0")"
else
    fail "lftp session failed for: $(basename "$0")"
fi

# Path to CHISTORY.TXT in the temporary directory
temp_file_path="$temp_dir/$remote_filename"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$temp_file_path" ] || [ ! -s "$temp_file_path" ]; then
    fail "Download failed: $remote_filename. Could not find file: $temp_file_path"
fi

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$temp_file_path" | while IFS= read -r line; do
    # Remove quotes and then extract fields
    clean_line=$(echo "$line" | sed 's/"//g')
    IFS=, read -r _ event_id month day year hour min sec _ <<<"$clean_line"

    if [[ $event_id =~ ^[0-9]+$ ]]; then
        # Format event timestamp, pad month for date directory, and construct event directory path
        event_timestamp=$(printf '%04d-%02d-%02dT%02d:%02d:%02d' "$year" "$month" "$day" "$hour" "$min" "$sec")
        formatted_month=$(printf '%02d' "$month")
        date_dir="$year-$formatted_month"
        event_dir_path="$output_dir/$date_dir/$meter_id/$event_id"

        # Check if the event directory exists and has all the files
        if [ -d "$event_dir_path" ]; then
            non_empty_files_count=$(find "$event_dir_path" -type f ! -empty -print | wc -l)
            
            if [ "$non_empty_files_count" -eq $files_per_event ]; then
                log "Complete directory for event: $event_id"

            elif [ "$non_empty_files_count" -ne 0 ]; then
                #TODO: Handle this case
                log "Incomplete directory for event: $event_id"
            fi

        else
            log "No event directory found, proceeding to download event: $event_id"

            # Output the event_id and date_dir back to download.sh to parse through
            echo "$event_id,$date_dir,$event_timestamp"
        fi

    else
        fail "Skipping line: $line, not entirely numeric. Check parsing."
        loop_success=false

    fi

done

# After the loop, check the flag and log accordingly
if [ "$loop_success" = true ]; then
    log "Successfully processed all events."
else
    log "Finished processing with some errors."
fi
