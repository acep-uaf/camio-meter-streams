#!/bin/bash

# Logging in to the FTP server and checking the connection
ftp -inv $FTP_METER_SERVER_IP <<EOF
user $FTP_METER_USER $FTP_METER_USER_PASSWORD
# Add any commands here to navigate to the correct directory or check the presence of files

bye
EOF

# Check exit status of FTP command
if [ $? -ne 0 ]; then
  echo "FTP connection to meter failed."
  exit 1
else
  echo "FTP connection to meter succeeded."
  exit 0
fi
