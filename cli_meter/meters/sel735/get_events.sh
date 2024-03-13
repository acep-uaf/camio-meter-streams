#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from download.sh
# - accepts 2 arguments: $meter_ip and $output_dir
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <meter_ip> <output_dir>"
    exit 1
fi

# TODO: Move these variable? Into config file?
REMOTE_TARGET_FILE="CHISTORY.TXT"
FILES_PER_EVENT=12

meter_ip=$1
output_dir=$2

# Connect to meter and get CHISTORY.TXT
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $output_dir
mget $REMOTE_TARGET_FILE
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
target_path="$output_dir/$REMOTE_TARGET_FILE"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$target_path" ] || [ ! -s "$target_path" ]; then
    log "Download failed: $REMOTE_TARGET_FILE" "err"
    exit 1
fi

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$target_path" | while IFS= read -r line; do
    event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

    if [[ $event_id =~ ^[0-9]+$ ]]; then
        event_dir_path="$output_dir/level0/$event_id"
        
        log "Checking for event: $event_id in directory: $event_dir_path"

        if [ -d "$event_dir_path" ]; then
            non_empty_files_count=$(find "$event_dir_path" -type f ! -empty -print | wc -l)

            if [ "$non_empty_files_count" -eq $FILES_PER_EVENT ]; then
                log "Complete directory for event: $event_id"
            elif [ "$non_empty_files_count" -ne 0 ]; then
                log "Incomplete event: $event_id" "warn"
            fi
        else
            log "No event directory found: $event_id" "warn"
            echo "$event_id"
        fi
    else
        log "Skipping line: $line, not entirely numeric. Check parsing." "warn"
    fi
done

log "Completed processing all events listed in $REMOTE_TARGET_FILE."
