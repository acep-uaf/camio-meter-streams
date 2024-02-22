#!/bin/bash

# This file is here to test connection to meter

LOG_FILE="connect_to_meter.log"

# Logging in to the FTP server and checking the connection
FTP_OUTPUT=$(ftp -inv $FTP_METER_SERVER_IP <<EOF
user $FTP_METER_USER $FTP_METER_USER_PASSWORD
bye
EOF
)

# Check exit status of FTP command
if [ $? -ne 0 ]; then
  log "FTP connection test to meter failed." "ERROR" "$LOG_FILE"
  echo "FTP connection test to meter failed."
  exit 1
else
  log "FTP connection test to meter succeeded." "SUCCESS" "$LOG_FILE"
  echo "$FTP_OUTPUT" | awk '
  BEGIN {
    print "\n"
    print "FTP Connection Report"
    print "--------------------------------"
  }
  /Connected to/ {
      print "Server IP: " $3
  }
  /User name okay, need password./ {
      print "Status: Username accepted."
  }
  /User logged in, proceed./ {
      print "Connection: Successful"
  }
  /Goodbye./ {
      print "Connection: Closed"
  }
  END {
    print "--------------------------------"
    print "End of Connection Report"
    print "\n"
  }' 
  exit 0
fi
