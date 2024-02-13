# After downloading is complete and up to data 
# this file does the following: 
# 1. renames (symlinks) the files 
# 2. creates metadata 
# 3. checksum/md5sum
######################################################
#!/bin/bash

# Base directory where the event directories are located
BASE_DIR="./EVENTS"


# Ensure that the FTP_METER_ID environment variable is set
if [ -z "$FTP_METER_ID" ]; then
    echo "FTP_METER_ID is not set. Exiting."
    exit 1
fi


# Directory where the files are downloaded
DOWNLOAD_DIR="$BASE_DIR/$FTP_METER_ID/level0"
# New directory for symlinks, metadata, and checksums
SYMLINKS_DIR="$BASE_DIR/$FTP_METER_ID/level0a"

echo "download dir" $DOWNLOAD_DIR
# Loop through each Event ID directory in the download directory
for event_dir in "$DOWNLOAD_DIR"/*/; do
    EVENT_ID=$(basename "$event_dir")
    NEW_EVENT_DIR="$SYMLINKS_DIR/$EVENT_ID"
    METADATA_DIR="$NEW_EVENT_DIR/metadata"
    CHECKSUM_DIR="$NEW_EVENT_DIR/checksums"

    # Ensure the directories exist
    mkdir -p "$NEW_EVENT_DIR" "$METADATA_DIR" "$CHECKSUM_DIR"

    # TODO GET this date from CHISTORY.TXT for event date
    # TODO get date of download from logs
    # Metadata values
    DOWNLOAD_DATE=$(date +"%Y-%m-%d %H:%M:%S")  # Current date and time

    echo "Processing files in event directory: $event_dir"

    # Loop through each file in the event directory
    for file in "$event_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            symlink_name="${FTP_METER_ID}_${EVENT_ID}_$filename"
            
            # Attempt to create the symlink in the new event directory
            ln -s "$file" "$NEW_EVENT_DIR/$symlink_name"
            if [ $? -ne 0 ]; then
                echo "Failed to create symlink for $file"
                continue  # Skip this file if the symlink creation failed
            fi

            echo "Creating/Writing to metadata.txt for $file"
            # Create or append metadata for the file
            {
                echo "File: $symlink_name"
                echo "DownloadedAt: $DOWNLOAD_DATE"
                echo "MeterID: $FTP_METER_ID"
                echo "EventID: $EVENT_ID"
                echo "DataLevel: Level0a"
                echo "----"
            } >> "$METADATA_DIR/metadata.txt"

            # Compute and store checksum
            md5sum "$file" > "$CHECKSUM_DIR/${symlink_name}.md5"
        else
            echo "No file found for $file"
        fi
    done
done

echo "Metadata, symlinks and checksums created for files in $SYMLINKS_DIR."