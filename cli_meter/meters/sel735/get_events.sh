#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from download.sh
# - accepts 2 arguments: $meter_ip and $output_dir
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <meter_ip> <meter_id> <output_dir>"
    exit 1
fi

remote_target_file="CHISTORY.TXT"
remote_dir="EVENTS"
files_per_event=6

meter_ip=$1
meter_id=$2
output_dir=$3

# Connect to meter and get CHISTORY.TXT
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $remote_dir
lcd $output_dir
mget $remote_target_file
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session successful for: $(basename "$0")"
else
    log "lftp session failed for: $(basename "$0")" "err"
    exit 1
fi

# Full path to CHISTORY.TXT
# TODO: Rename variable "target_path"?
target_path="$output_dir/$remote_target_file"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$target_path" ] || [ ! -s "$target_path" ]; then
    log "Download failed: $remote_target_file" "err"
    exit 1
fi

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$target_path" | while IFS= read -r line; do
    # event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

    # Extract event_id, year, and month
    read event_id year month <<<$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2, $5, $3}')
    log "$event_id $year $month"

    if [[ $event_id =~ ^[0-9]+$ ]]; then
        date_dir="$year-$month"
        event_dir_path="$output_dir/$date_dir/$meter_id/$event_id"
        
        log "Checking for event: $event_id in directory: $event_dir_path"

        if [ -d "$event_dir_path" ]; then
            non_empty_files_count=$(find "$event_dir_path" -type f ! -empty -print | wc -l)

            if [ "$non_empty_files_count" -eq $files_per_event ]; then
                log "Complete directory for event: $event_id"
            elif [ "$non_empty_files_count" -ne 0 ]; then
                log "Incomplete event: $event_id" "warn"
            fi
        else
            log "No event directory found: $event_id" "warn"
            echo "$event_id,$date_dir"
        fi
    else
        log "Skipping line: $line, not entirely numeric. Check parsing." "warn"
    fi
done

log "Completed processing all events listed in $remote_target_file."
