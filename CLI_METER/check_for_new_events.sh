#!/bin/bash

REMOTE_DIR="EVENTS"
LOCAL_DIR=$REMOTE_DIR
REMOTE_FILE="CHISTORY.TXT"
LOG_FILE="ftp_download_chistory.log"

# Function to log messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "Starting FTP download script."

# Load FTP connection details from .env file
if [ -f ".env" ]; then
    export $(cat .env | xargs)
    log "Loaded FTP connection details from .env file."
else
    log "Error: .env file not found. Exiting script."
    exit 1
fi

# Create local directory if it doesn't exist
if mkdir -p "$LOCAL_DIR"; then
    log "Local directory: $LOCAL_DIR exists."
else
    log "Error: Failed to create local directory $LOCAL_DIR."
fi

# Start lftp session to download the file
lftp -u "$FTP_USER,$FTP_PASSWORD" "$FTP_SERVER" <<EOF
set xfer:clobber on
cd $REMOTE_DIR
lcd $LOCAL_DIR
mget $REMOTE_FILE
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session completed successfully."
else
    log "lftp session encountered an error."
fi

# Check if the CHISTORY.TXT file was successfully downloaded
if [ -f "$LOCAL_DIR/$REMOTE_FILE" ]; then
    log "File $REMOTE_FILE downloaded successfully, starting to parse data..."

    # Parse and check for matching directory based on the second column
    while IFS= read -r number; do
    # Check if $number is entirely numeric
    if [[ $number =~ ^[0-9]+$ ]]; then  
        if [ -d "$LOCAL_DIR/$METER_ID/level0/$number" ]; then
            log "Directory exits for most recent event #: $number. Nothing to download, you're all up to date."
            echo "Nothing to download, you're all up to date."
            exit 1
        else
            log "Directory does not exist: $LOCAL_DIR/$METER_ID/level0/$number"
            log "Download event files $number here"
            # chmod +x download_by_id.sh
            # ./download_by_id.sh $FTP_SERVER $number"
        fi
    fi
    done < <(awk -F, 'NR > 3 { gsub(/"/, "", $2); print $2 }' "$LOCAL_DIR/$REMOTE_FILE")


else
    log "Failed to download $REMOTE_FILE from FTP server."
fi

log "FTP download script completed."
