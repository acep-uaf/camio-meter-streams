#!/bin/bash

REMOTE_DIR="EVENTS"
LOCAL_DIR="EVENTS"
REMOTE_FILE="CHISTORY.TXT"

# Load FTP connection details from .env file
if [ -f ".env" ]; then
    export $(cat .env | xargs)
else
    echo ".env file not found"
    exit 1
fi

## Create local directory if it doesn't exist
mkdir -p "$LOCAL_DIR"

# Start lftp session
lftp -u "$FTP_USER,$FTP_PASSWORD" "$FTP_SERVER" <<EOF
cd $REMOTE_DIR
lcd $LOCAL_DIR
mget $REMOTE_FILE
bye
EOF