#!/bin/bash
#########################################
# This script zips the event files in the 
# source directory and saves the zip file 
# in the destination directory.
# 
# It takes 3 arguments:
# 1. output dir: The directory containing the event files
# 2. zipped output dir: The directory where the zip file will be saved
# 3. event id: The ID of the event
#
# 
#########################################


# Check for exactly 3 arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source_dir> <dest_dir> <event_id>"
    exit 1
fi

source_dir="$1"
dest_dir="$2"
event_id="$3"

zip -r -q "${dest_dir}/${event_id}.zip" "$source_dir"/* 

if [ $? -eq 0 ]; then
    echo "$event_id Validated and Zipped.--->"
else
    echo "Error zipping files for $event_id"
    exit 1
fi
