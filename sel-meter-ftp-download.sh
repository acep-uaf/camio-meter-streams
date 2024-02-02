#!/bin/bash

# Check if secrets.json exists in current directory
if [ ! -f secrets.json ]; then
	echo "Please enter the following details:"
	read -p "Enter FTP username" FTP_USER
	read -sp "Enter FTP password" FTP_PASSWORD
	echo
	read -p "Enter FTP server IP address: " FTP_SERVER
	# Set default remote and local paths
	FTP_REMOTE_PATH ="/"
	LOCAL_PATH="/EVENTS/"
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

#TODO: Try catch to connect to meter
#Return: Result
# lftp -u $FTP_USER,$FTP_PASSWORD $FTP_SERVER

## Create local directory if it doesn't exist
## TODO: Test for proper path
# mkdir -p "$LOCAL_PATH"


## Using lftp to mirror the directory
## TODO: Return Login success or failure
#lftp -u "$FTP_USER,$FTP_PASS" -e "mirror --verbose --only-newer $FTP_REMOTE_PATH $LOCAL_PATH; quit" $FTP_SERVER

