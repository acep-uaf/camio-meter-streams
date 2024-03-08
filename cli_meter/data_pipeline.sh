#!/bin/bash

# This file is a wrapper script for the data pipeline

# Source the commons.sh file
source commons.sh

date=$(date '+%Y-%m')

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    log "Error: .env file not found. Exiting script." "err"
    exit 1
fi

# Evnironment Variables 
# $METER_IP
# $METER_ID
# $USERNAME
# $PASSWORD
# $REMOTE_METER_PATH
# $METER_TYPE
# $LOCATION
# $DATA_TYPE

# make all scripts executable 
chmod +x *.sh

# 
exec "meters/$METER_TYPE/download.sh" $METER_IP "$DATA_TYPE/$date/$METER_ID"

# Call the update-event-files script to see if there are new files available,
# if so, the script will call the download_by_id script.
# after download create metadata and checksums
#./update_event_files.sh
#if [ $? -ne 0 ]; then
#  log "Updating event files failed." "err"
#  exit 1
#fi


# Archive the data (copy files to archive server)
# ./archive_data.sh
# if [ $? -ne 0 ]; then
#  log "Archiving data failed." "err"
#  exit 1
# fi

log "Data processing completed successfully."
