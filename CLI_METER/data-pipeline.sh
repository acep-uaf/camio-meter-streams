#!/bin/bash

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    log "Error: .env file not found. Exiting script."
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

# Call the connection script (to see if we can connect to the meter)
./connect-to-meter.sh 
if [ $? -ne 0 ]; then
  echo "Connection to meter failed."
  exit 1
fi

# Fetch the NEW data (downloading data in local dir)
./sel-meter-ftp-download.sh
if [ $? -ne 0 ]; then
  echo "Fetching data failed."
  exit 1
fi

# ONCE ALL DATA IS DOWNLOADED UP TO DATE

# Organize the files (renaming files and creating metadata.txt)
# rename data/ metadata
./organize-files.sh
if [ $? -ne 0 ]; then
  echo "Organizing files failed."
  exit 1
fi

# Archive the data (copy files to archive server)
./archive-data.sh
if [ $? -ne 0 ]; then
  echo "Archiving data failed."
  exit 1
fi

echo "Data processing completed successfully."
