#!/bin/bash

# This file is a wrapper script for the data pipeline

# Source the utils.sh file
source utils.sh

# Set the log file
LOG_FILE="data_pipeline.log"

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    log "Error: .env file not found. Exiting script." "INFO" "$LOG_FILE"
    echo "Error: .env file not found. Exiting script."
    exit 1
fi

# Evnironment Variables 
# $FTP_METER_SERVER_IP
# $FTP_METER_NAME
# $FTP_METER_ID
# $FTP_METER_USER
# $FTP_METER_USER_PASSWORD
# $FTP_REMOTE_METER_PATH
# $LOCAL_PATH

# make all scripts executable 
chmod +x *.sh

# Call the connection script (to see if we can connect to the meter)
./connect_to_meter.sh 
if [ $? -ne 0 ]; then
  echo "Connection to meter failed."
  log "Connection to meter failed." "ERROR" "$LOG_FILE"
  exit 1
fi


# Call the update-event-files script to see if there are new files available,
# if so, the script will call the download_by_id script.
# after download create metadata and checksums
./update_event_files.sh
if [ $? -ne 0 ]; then
  echo "Updating event files failed."
  log "Updating event files failed." "ERROR" "$LOG_FILE"
  exit 1
fi


# Archive the data (copy files to archive server)
# ./archive_data.sh
# if [ $? -ne 0 ]; then
#  echo "Archiving data failed."
#  log "Archiving data failed." "ERROR" "$LOG_FILE"
#  exit 1
# fi

echo "Data processing completed successfully."
echo -e "\n"
log "Data processing completed successfully." "SUCCESS" "$LOG_FILE"
