#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from data_pipeline.sh
# - accepts 1 argument: $meter_ip
# - uses environment variables
# - currently iterates over 
#################################

REMOTE_TARGET_FILE="CHISTORY.TXT"
FILES_PER_EVENT=12
meter_ip=$1

# Ensure meter IP is provided
if [[ -z "$meter_ip" ]]; then
    echo "Meter IP argument is required."
    exit 1
fi

# Connect to meter and get CHISTORY.TXT
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $REMOTE_METER_PATH
lcd $DATA_TYPE
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
FULL_PATH="$DATA_TYPE/$REMOTE_TARGET_FILE"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$FULL_PATH" ] || [ ! -s "$FULL_PATH" ]; then
    log "Download failed: $REMOTE_TARGET_FILE" "err"
    exit 1
fi

# Parse each line to get event ID and then extract timestamp components from the line
while IFS= read -r line; do
    # Extract event ID using awk, assuming it's the second field in the line
    event_id=$(echo "$line" | awk -F, '{gsub(/"/, "", $2); print $2}')

    # Check if $event_id is entirely numeric
    if [[ $event_id =~ ^[0-9]+$ ]]; then
        FULL_PATH_EVENT_DIR="$DATA_TYPE/$METER_ID/level0/$event_id"

        if [ -d "$FULL_PATH_EVENT_DIR" ]; then
            log "Checking event directory: $event_id"

            # Count the number of non-empty files in the directory
            non_empty_files_count=$(find "$FULL_PATH_EVENT_DIR" -type f ! -empty -print | wc -l)

            # Check if the directory is complete or incomplete
            if [ "$non_empty_files_count" -eq 12 ]; then
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
done < <(awk 'NR > 3' "$DATA_TYPE/$REMOTE_TARGET_FILE")

log "Completed processing all events listed in $REMOTE_TARGET_FILE."

echo "Finished downloading and updating events successfully."
