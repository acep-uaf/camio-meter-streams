#!/bin/bash

LOG_FILE="ftp_transfer.log"

# Log function definition
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}


#log "Remote Path: $FTP_REMOTE_PATH"
log "Local Path: $LOCAL_PATH"
log "Remote Path: $FTP_REMOTE_METER_PATH"

DIR_PATH="$LOCAL_PATH/$FTP_METER_ID/level0"

## Create local directory if it doesn't exist
mkdir -p "$DIR_PATH"

# Start lftp session
lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$FTP_METER_SERVER_IP" <<EOF
cd EVENTS  
lcd "$DIR_PATH"             
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