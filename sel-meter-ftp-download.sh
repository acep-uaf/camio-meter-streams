#!/bin/bash

# Path to event files
FTP_REMOTE_PATH ="EVENTS"

# Check if secrets.json exists in current directory
if [ ! -f secrets.json ]; then
	echo "Please enter the following FTP server details:"
	echo
	read -p "IP address: " FTP_SERVER
	read -p "Download path: " LOCAL_PATH
	echo
	read -p "username: " FTP_USER
	read -sp "password: " FTP_PASSWORD

else
	# FTP server details from secrets.json
	FTP_SERVER=$(jq -r '.ftp_server' secrets.json)
	FTP_USER=$(jq -r '.ftp_username' secrets.json)
	FTP_PASSWORD=$(jq -r '.ftp_password' secrets.json)
	LOCAL_PATH=$(jq -r '.local_path' secrets.json)
fi

echo "Remote Path: Attempting to download from $FTP_REMOTE_PATH"

# Create local directory if it doesn't exist
mkdir -p "$LOCAL_PATH"

# Attempt to login and perform operations
lftp "$FTP_SERVER" -e "bye" -u "$FTP_USER,$FTP_PASSWORD"
login_status=$?

if [ $login_status -ne 0 ]; then
    echo "Failed to log in to the FTP server: $FTP_SERVER. Please check your credentials and server address."
    exit 1
else
    echo "Successfully logged in to the FTP server. Proceeding with file operations."
fi

## FIXME: mirror not copying contents/correct permissions to local directory
lftp "$FTP_SERVER" -u "$FTP_USER,$FTP_PASSWORD" <<EOF
mirror $FTP_REMOTE_PATH $LOCAL_PATH
quit
EOF

# Check the status of the lftp operations
if [ $? -ne 0 ]; then
    echo "Failed to complete the FTP operations."
    exit 1
else
    echo "FTP operations completed successfully."
	echo "Files downloaded to ./$LOCAL_PATH."
fi
