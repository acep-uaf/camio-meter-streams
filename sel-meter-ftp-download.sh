#!/bin/bash

LOG_FILE="ftp_transfer.log"

# Log function definition
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Check if secrets.json exists and read FTP details from it
if [ ! -f secrets.json ]; then
    echo "secrets.json file not found. Exiting."
    exit 1
fi

# FTP server details from secrets.json
FTP_SERVER=$(jq -r '.ftp_server' secrets.json)
FTP_USER=$(jq -r '.ftp_username' secrets.json)
FTP_PASSWORD=$(jq -r '.ftp_password' secrets.json)
FTP_REMOTE_PATH=$(jq -r '.ftp_remote_path' secrets.json)
LOCAL_PATH=$(jq -r '.local_path' secrets.json)

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