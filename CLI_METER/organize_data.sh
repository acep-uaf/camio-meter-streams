# After downloading is complete and up to data 
# this file does the following: 
# 1. renames (symlinks) the files 
# 2. creates metadata 
# 3. checksum/md5sum
######################################################
#!/bin/bash

# Function to extract the download date from logs (to ot-dev from meter)
get_download_date_from_logs() {
    # Replace 'logfile.log' with the path to your actual log file
    local log_file='/home/agreer5/repos/data-ducks-STREAM/logs/ftp_download_chistory.log'
    # This command assumes that the download date is in a line containing 'Download completed' and is the first date in the line
    local download_date=$(grep 'Download completed' "$log_file" | head -1 | awk '{print $1, $2}')
    echo "$download_date"
}

# Function to extract event meter download date from CHISTORY.TXT (meter event creation)
get_event_date_from_chistory() {
    local chistory_file='CHISTORY.TXT'
    local event_id="$1"
    # This awk command extracts the date components and prints them in 'YYYY-MM-DD HH:MM:SS.mmm' format
    local event_date=$(awk -F, -v id="$event_id" '$2 == id { printf "%04d-%02d-%02d %02d:%02d:%02d.%03d\n", $5, $3, $4, $6, $7, $8, $9 }' "$chistory_file" | head -1)
    echo "$event_date"
}

# Base directory where the event directories are located
BASE_DIR="./EVENTS"

DOWNLOAD_DATE=$(get_download_date_from_logs)
EVENT_DATE=$(get_event_date_from_chistory "10001")

echo "Download Date: $DOWNLOAD_DATE"
echo "Event Date: $EVENT_DATE"

echo "download dir" $DOWNLOAD_DIR
# Loop through each Event ID directory in the download directory
for event_dir in "$DOWNLOAD_DIR"/*/; do
    EVENT_ID=$(basename "$event_dir")

    echo "Processing files in event directory: $event_dir"

    # Loop through each file in the event directory
    for file in "$event_dir"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")

            echo "Creating/Writing to metadata.txt for $file"
            # Create or append metadata for the file
            {
                echo "File: $filename"
                echo "DownloadedAt: $DOWNLOAD_DATE"
                echo "MeterID: $FTP_METER_ID"
                echo "EventID: $EVENT_ID"
                echo "DataLevel: Level0a"
                echo "----"
            } >> "$event_dir/metadata.txt"

            # Compute and store checksum
            md5sum "$file" > "$event_dir/${filename}.md5"
        else
            echo "No file found for $file"
        fi
    done
done

echo "Metadata and checksums created for files in $event_dir."