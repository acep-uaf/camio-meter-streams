#!/bin/bash

# This file is a wrapper script for the data pipeline

# Source the commons.sh file
source commons.sh

DATE=$(date '+%Y-%m')

# Load the .env file
if [ -f .env ]; then
    export $(cat .env | xargs)
else
    log "Error: .env file not found. Exiting script." "err"
    exit 1
fi

# Evnironment Variables (these will be removed and put into config.yaml and username/password to .env)
# METER_IP
# METER_ID
# USERNAME
# PASSWORD
# REMOTE_METER_PATH
# METER_TYPE
# LOCATION
# DATA_TYPE

# make all scripts executable 
chmod +x *.sh

# 
exec "meters/$METER_TYPE/download.sh" "$METER_IP" "$LOCATION/$DATA_TYPE/$DATE/$METER_ID"