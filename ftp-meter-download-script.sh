#!/bin/bash

# FTP server details
FTP_SERVER=""
FTP_REMOTE_PATH=""
LOCAL_PATH=""

# Prompt for username and password
read -p "Enter FTP username: " FTP_USER
read -sp "Enter FTP password: " FTP_PASS
echo

# Create local directory if it doesn't exist
mkdir -p "$LOCAL_PATH"

# Using lftp to mirror the directory
lftp -u "$FTP_USER,$FTP_PASS" -e "mirror --verbose --only-newer $FTP_REMOTE_PATH $LOCAL_PATH; quit" $FTP_SERVER
