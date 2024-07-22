#!/bin/bash
# ==============================================================================
# Script Name:        get_events.sh
# Description:        This script returns a list of event IDs that need to be
#                     downloaded by checking the CHISTORY.TXT file on the meter.
#
# Usage:              ./get_events.sh <meter_ip> <meter_id> <output_dir> [<max_age_days>]
# Called by:          download.sh
#
# Arguments:
#   meter_ip          Meter IP address
#   meter_id          Meter ID
#   output_dir        Base directory where the event data will be stored
#   max_age_days      Maximum age of events to be downloaded (optional)
#                     If provided, events older than max_age_days will be skipped  
#                     If not provided, all events will be downloaded
#
# Requirements:       lftp
#                     common_sel735.sh
#                     common_utils.sh
#                     $USERNAME and $PASSWORD environment variables
# ==============================================================================

current_dir=$(dirname "$(readlink -f "$0")")
log "Current directory: $current_dir"
script_name=$(basename "$0")
source "$current_dir/common_sel735.sh"
source "$current_dir/../../common_utils.sh"

# Check that the number of arguments is between 3 and 4
[ "$#" -lt 3 ] || [ "$#" -gt 4 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_ip> <meter_id> <output_dir> [max_age_days]"

meter_ip=$1
meter_id=$2
output_dir=$3
max_age_days=$4

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

lftp_exit_code=$?

# Check the exit status of lftp command
[ $lftp_exit_code -eq 0 ] && log "Downloaded remote file: $remote_filename" || failure $STREAMS_LFTP_FAIL "Failed to download remote file: $remote_filename"

# Path to CHISTORY.TXT in the temporary directory
temp_file_path="$temp_dir/$remote_filename"

# Check if CHISTORY.TXT exists and is not empty
[ -s "$temp_file_path" ] || failure $STREAMS_FILE_NOT_FOUND "File does not exist or is empty: $remote_filename"

# Calculate the max allowable date if max_age_days is provided
if [[ -n "$max_age_days" ]]; then
    max_date=$(calculate_max_date "$max_age_days")
    log "Only downloading events newer than: $max_date"
fi

# Parse CHISTORY.TXT event data starts from line 4
awk 'NR > 3' "$temp_file_path" | while IFS= read -r event_line; do
    # Remove quotes and then extract fields
    clean_line=$(echo "$event_line" | sed 's/"//g')
    IFS=, read -r _ event_id month day year hour min sec _ <<<"$clean_line"
    [[ ! $event_id =~ ^[0-9]+$ ]] && { log "Parsing error, skipping line: $event_line."; continue; }

    # Format event timestamp
    event_date=$(printf '%04d-%02d-%02d' "$year" "$month" "$day")
    event_timestamp=$(printf '%04d-%02d-%02dT%02d:%02d:%02d' "$year" "$month" "$day" "$hour" "$min" "$sec")
    
    # Check if the event is within the max_age_days date range
    if [[ -z "$max_age_days" ]] || [[ "$event_date" > "$max_date" ]] || [[ "$event_date" == "$max_date" ]]; then
        date_dir=$(generate_date_dir "$year" "$month" "$output_dir")
        event_dir_path="$output_dir/$date_dir/$meter_id/$event_id"

        # If the event directory does not exist, print the event info
        if [ ! -d "$event_dir_path" ]; then
            log "Proceeding to download event: $event_id"
            echo "$event_id,$date_dir,$event_timestamp"
        fi
    else
        log "Event $event_id is older than the specified date range, skipping."
        log "All events within $max_age_days day(s) have been processed"
        break
    fi
done