#!/bin/bash

# Check if secrets.json exists in current directory
if [ ! -f secrets.json ]; then
	echo "Please enter the following details:"
	read -p "Enter FTP username" FTP_USER
	read -sp "Enter FTP password" FTP_PASSWORD
	echo
	read -p "Enter FTP server IP address: " FTP_SERVER
	# Set default remote and local paths
	FTP_REMOTE_PATH ="EVENTS"
	LOCAL_PATH="EVENTS"
else
	# FTP server details from secrets.json
	FTP_SERVER=$(jq -r '.ftp_server' secrets.json)
	FTP_USER=$(jq -r '.ftp_username' secrets.json)
	FTP_PASSWORD=$(jq -r '.ftp_password' secrets.json)
	FTP_REMOTE_PATH=$(jq -r '.ftp_remote_path' secrets.json)
	LOCAL_PATH=$(jq -r '.local_path' secrets.json)
fi

echo "FTP Details:"
echo "Server: $FTP_SERVER"
echo "User: $FTP_USER"
echo "Remote Path: $FTP_REMOTE_PATH"
echo "Local Path: $LOCAL_PATH"

## Create local directory if it doesn't exist
## TODO: Test for proper path
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

lftp "$FTP_SERVER" -u "$FTP_USER,$FTP_PASSWORD" <<EOF
pget CHISTORY.TXT
quit
EOF

# Check the status of the lftp operations
if [ $? -ne 0 ]; then
    echo "Failed to complete the FTP operations."
    exit 1
else
    echo "FTP operations completed successfully."
fi