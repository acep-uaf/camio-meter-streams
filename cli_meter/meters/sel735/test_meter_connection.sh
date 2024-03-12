#!/bin/bash

#################################
# This script:
# - checks the connection to the meter
# - is called from data_pipeline.sh
# - uses environment variables
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <meter_ip>"
    exit 1
fi

# Logging in to the FTP server and checking the connection
ftp_output=$(ftp -inv $meter_ip <<EOF
user $USERNAME $PASSWORD
ls
bye
EOF
)

# Check if specific FTP error messages are present
if [[ "$ftp_output" =~ "421 Service not available, closing control connection." && "$ftp_output" =~ "Not connected." ]]; then
    # Log diagnostic information if FTP connection failed
    echo "The FTP service is not available, and the connection was not established."
    log "FTP Server IP: $meter_ip is not available." "err"
    # Handle the error, e.g., exit the script or try to reconnect
    return 1
else
    log "FTP connection test to meter succeeded."
    # Optionally, print a formatted connection report to stdout
    echo "$ftp_output" | awk '
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
    return 0
fi
