#!/bin/bash

# Check for correct number of arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <output_dir> <event_id>"
    exit 1
fi

output_dir=$1
event_id=$2

# Function to check for problematic FTP connections
check_ftp_connections() {
    # Example using netstat, adjust for your FTP server's IP and port as necessary
    if netstat -ant | grep ':21' | grep -v 'ESTABLISHED'; then
        echo "Detected non-standard FTP connections that may need investigation."
        # Handle or log this situation as needed
        return 1 # Indicate a potential issue
    else
        echo "No problematic FTP connections detected."
        return 0 # All clear
    fi
}

# Cleanup function declaration
cleanup() {
    event_dir="$output_dir/level0/$event_id"

    # Call the new check function before proceeding
    check_ftp_connections || exit 1

    if [ -d "$event_dir" ]; then
        echo "Removing directory: $event_dir"
        rm -rf "$event_dir"
    else
        echo "No path found: $event_dir"
    fi
}
cleanup
