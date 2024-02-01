#!/bin/bash

# FTP server details
FTP_SERVER=$(jq -r '.ftp_server' secrets.json)
FTP_USER=$(jq -r '.ftp_username' secrets.json)
FTP_PASSWORD=$(jq -r '.ftp_password' secrets.json)
FTP_REMOTE_PATH=$(jq -r '.ftp_remote_path' secrets.json)
LOCAL_PATH=$(jq -r '.local_path' secrets.json)

echo $FTP_SERVER $FTP_USER $FTP_PASSWORD $FTP_REMOTE_PATH $LOCAL_PATH

# Prompt for username and password
#read -p "Enter FTP username: " FTP_USER
#read -sp "Enter FTP password: " FTP_PASS
#echo

## Create local directory if it doesn't exist
## TODO: Test for proper path
#mkdir -p "$LOCAL_PATH"


## Using lftp to mirror the directory
## TODO: Return Login success or failure
#lftp -u "$FTP_USER,$FTP_PASS" -e "mirror --verbose --only-newer $FTP_REMOTE_PATH $LOCAL_PATH; quit" $FTP_SERVER
