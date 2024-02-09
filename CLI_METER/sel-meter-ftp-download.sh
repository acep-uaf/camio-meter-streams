#!/bin/bash

LOG_FILE="ftp_transfer.log"

# Log function definition
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Evnironment Variables 
FTP_SERVER=$FTP_SERVER
FTP_USER=$FTP_USER
FTP_PASSWORD=$FTP_PASSWORD
FTP_REMOTE_PATH=$FTP_REMOTE_PATH
LOCAL_PATH=$LOCAL_PATH

#log "Remote Path: $FTP_REMOTE_PATH"
log "Local Path: $LOCAL_PATH"
log "Remote Path: $FTP_REMOTE_PATH"
## Create local directory if it doesn't exist
mkdir -p "$LOCAL_PATH"

# Start lftp session
lftp -u "$FTP_USER,$FTP_PASSWORD" "$FTP_SERVER" <<EOF
cd EVENTS
lcd EVENTS
mget *
bye
EOF

# Check if the lftp operation was successful
if [ $? -ne 0 ]; then
    log "Failed to list files from FTP server. Exiting."
    exit 1
fi

log "FTP download operations completed."

# End of the script logging
log "FTP download script completed."