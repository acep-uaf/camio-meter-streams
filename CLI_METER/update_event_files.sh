#!/bin/bash

REMOTE_TARGET_FILE="CHISTORY.TXT"
LOG_FILE="ftp_download_chistory.log"

# Function to log messages with a timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log "Checking for updates..."

# Create local directory if it doesn't exist
if mkdir -p "$LOCAL_PATH"; then
    log "Local directory: $LOCAL_PATH exists."
else
    log "Error: Failed to create local directory $LOCAL_PATH."
fi

# Start lftp session to download the file
lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$FTP_METER_SERVER_IP" <<EOF
set xfer:clobber on
cd $FTP_REMOTE_METER_PATH
lcd $LOCAL_PATH
mget $REMOTE_TARGET_FILE
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session completed successfully."
else
    log "lftp session encountered an error."
fi

# Check if the CHISTORY.TXT file was successfully downloaded
if [ -f "$LOCAL_PATH/$REMOTE_TARGET_FILE" ]; then
    log "File $REMOTE_TARGET_FILE downloaded successfully, starting to parse data..."

    # Parse and check for matching directory based on the second column
    while IFS= read -r number; do
    # Check if $number is entirely numeric
    if [[ $number =~ ^[0-9]+$ ]]; then  
        if [ -d "$LOCAL_PATH/$FTP_METER_ID/level0/$number" ]; then
            log "Directory exits for most recent event #: $number. Nothing to download, you're all up to date."
            echo "Nothing to download, you're all up to date."
            exit 0
        else
            log "Directory does not exist: $LOCAL_PATH/$FTP_METER_ID/level0/$number"
            log "Download event files $number here"
            chmod +x download_by_id.sh
            ./download_by_id.sh "$FTP_METER_SERVER_IP" "$number"
        fi
    fi
    done < <(awk -F, 'NR > 3 { gsub(/"/, "", $2); print $2 }' "$LOCAL_PATH/$REMOTE_TARGET_FILE")


else
    log "Failed to download $REMOTE_TARGET_FILE from FTP server."
fi

log "update_event_files.sh completed"
