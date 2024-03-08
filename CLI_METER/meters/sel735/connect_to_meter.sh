#!/bin/bash

#################################
# This script:
# - checks the connection to the meter
# - is called from data_pipeline.sh
# - uses environment variables
#################################

# Logging in to the FTP server and checking the connection
FTP_OUTPUT=$(ftp -inv $FTP_METER_SERVER_IP <<EOF
user $FTP_METER_USER $FTP_METER_USER_PASSWORD
ls
bye
EOF
)

# Check if specific FTP error messages are present
if [[ "$FTP_OUTPUT" =~ "421 Service not available, closing control connection." && "$FTP_OUTPUT" =~ "Not connected." ]]; then
    # Log diagnostic information if FTP connection failed
    echo "The FTP service is not available, and the connection was not established."
    log "FTP Server IP: $FTP_METER_SERVER_IP is not available." "err"
    # Handle the error, e.g., exit the script or try to reconnect
    exit 1
else
    log "FTP connection test to meter succeeded."
    # Optionally, print a formatted connection report to stdout
    echo "$FTP_OUTPUT" | awk '
    BEGIN {
      print "\nFTP Connection Report"
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
      print "End of Connection Report\n"
    }'
    exit 0
fi
