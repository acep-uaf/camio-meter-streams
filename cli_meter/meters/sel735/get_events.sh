#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from data_pipeline.sh
# - accepts 2 arguments: $meter_ip and $output_dir
# - uses environment variables
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <meter_ip> <output_dir>"
    exit 1
fi

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
FULL_PATH="$output_dir/$REMOTE_TARGET_FILE"

echo "Processing CHISTORY.TXT from: $FULL_PATH"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$FULL_PATH" ] || [ ! -s "$FULL_PATH" ]; then
    log "Download failed: $REMOTE_TARGET_FILE" "err"
    exit 1
fi

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$FULL_PATH" | while IFS= read -r line; do
    event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

    if [[ $event_id =~ ^[0-9]+$ ]]; then
        FULL_PATH_EVENT_DIR="$output_dir/level0/$event_id"
        
        log "Checking for event: $event_id in directory: $FULL_PATH_EVENT_DIR"

        if [ -d "$FULL_PATH_EVENT_DIR" ]; then
            non_empty_files_count=$(find "$FULL_PATH_EVENT_DIR" -type f ! -empty -print | wc -l)

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
        log "Skipping line: $line, not entirely numeric" "warn"
    fi
done

log "Completed processing all events listed in $REMOTE_TARGET_FILE."
