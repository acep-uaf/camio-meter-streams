#!/bin/bash

HOME=/home/agreer5/repos/data-ducks-STREAM

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    echo "Error: .env file not found. Exiting script." | tee -a "$HOME/rsync_ot_dev.log"
    exit 1
fi


# Define new paths for lock and log files where the user has write access
LOCK_FILE="$HOME/rsync_ot_dev.lock"
LOG_FILE="$HOME/rsync_ot_dev.log"

# Check for lock file
if [ -e "$LOCK_FILE" ]; then
    echo "Lock file exists. Exiting." | tee -a "$LOG_FILE"
    exit 1
else
    # Create lock file
    touch "$LOCK_FILE"
fi

# Rsync command with logging
rsync -a -e "ssh -o StrictHostKeyChecking=accept-new" "$LOCAL_PATH" "$REMOTE_USER"@"$REMOTE_HOST":"$REMOTE_PATH" | tee -a "$LOG_FILE"

# Log the date and time of operation
echo "Sync completed at: $(date --iso-8601=seconds)" | tee -a "$LOG_FILE"

# Remove lock file
rm "$LOCK_FILE"



