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
# Function to generate date directory name
generate_date_dir() {
    local year=$1
    local month=$2
    local base_output_dir=$3

    formatted_month=$(printf '%02d' "$month")
    date_dir="$year-$formatted_month"
    echo "$date_dir"
}

# Function to check if the event is within the max age
is_within_max_age() {
    local event_timestamp=$1
    local max_age_days=$2

    event_date=$(date -d "$event_timestamp" +%s)
    current_date=$(date +%s)
    max_age_seconds=$((max_age_days * 86400))

    if (( (current_date - event_date) <= max_age_seconds )); then
        return 0
    else
        return 1
    fi
}

# ==============================================================================

current_dir=$(dirname "$(readlink -f "$0")")
log "Current directory: $current_dir"
script_name=$(basename "$0")
source "$current_dir/common_sel735.sh"
source "$current_dir/../../common_utils.sh"

# Check if the correct number of arguments are passed
[ "$#" -ne 4 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <meter_ip> <meter_id> <output_dir> <max_age_days>"

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

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$temp_file_path" | while IFS= read -r event_line; do
    # Remove quotes and then extract fields
    clean_line=$(echo "$event_line" | sed 's/"//g')
    IFS=, read -r _ event_id month day year hour min sec _ <<<"$clean_line"
    [[ ! $event_id =~ ^[0-9]+$ ]] && { log "Parsing error, skipping line: $event_line."; continue; }

    # Format event timestamp, pad month for date directory, and construct event directory path
    event_timestamp=$(printf '%04d-%02d-%02dT%02d:%02d:%02d' "$year" "$month" "$day" "$hour" "$min" "$sec")
    if is_within_max_age "$event_timestamp" "$max_age_days"; then
        date_dir=$(generate_date_dir "$year" "$month" "$output_dir")
        event_dir_path="$output_dir/$date_dir/$meter_id/$event_id"

        # If the event directory does not exist, print the event ID else validate the directory
        if [ ! -d "$event_dir_path" ]; then
            log "No directory found, proceeding to download event: $event_id"
            echo "$event_id,$date_dir,$event_timestamp"
        else
            validate_complete_directory "$event_dir_path" "$event_id" && log "Complete directory for event: $event_id" || {
                log "Incomplete directory, proceeding to download event: $event_id"
                echo "$event_id,$date_dir,$event_timestamp"
            }
        fi
    else
        log "Event $event_id is older than max age, skipping."
        log "All events within $max_age_days days have been processed"
        break
    fi
done