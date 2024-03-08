#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from data_pipeline.sh
# - accepts 1 argument: $meter_ip
# - uses environment variables
# - currently iterates over 
#################################
# Source the commons.sh file
source commons.sh

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    log "Error: .env file not found. Exiting script." "err"
    exit 1
fi

REMOTE_TARGET_FILE="CHISTORY.TXT"
FILES_PER_EVENT=12
meter_ip=$1

# Ensure meter IP is provided
if [[ -z "$meter_ip" ]]; then
    echo "Meter IP argument is required."
    exit 1
fi

# Connect to meter and get CHISTORY.TXT
lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $FTP_REMOTE_METER_PATH
lcd $LOCAL_PATH
mget $REMOTE_TARGET_FILE
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session successful."
else
    log "lftp session failed." "err"
    exit 1
fi

# Full path to CHISTORY.TXT
FULL_PATH="$LOCAL_PATH/$REMOTE_TARGET_FILE"

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
        FULL_PATH_EVENT_DIR="$LOCAL_PATH/$FTP_METER_ID/level0/$event_id"

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
            echo "$event_id"

        fi
    else
        log "Skipping line: $line, not entirely numeric" "warn"
    fi
done < <(awk 'NR > 3' "$LOCAL_PATH/$REMOTE_TARGET_FILE")

log "Completed processing all events listed in $REMOTE_TARGET_FILE."

echo "Finished downloading and updating events successfully."