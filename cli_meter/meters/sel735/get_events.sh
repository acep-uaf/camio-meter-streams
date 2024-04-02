#!/bin/bash

#################################
# This script:
# - returns a list of event_id's that need to be downloaded
# - is called from download.sh
# - accepts 2 arguments: $meter_ip and $output_dir
#################################

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <meter_ip> <meter_id> <output_dir>"
    exit 1
fi

meter_ip=$1
meter_id=$2
output_dir=$3

files_per_event=6
remote_filename="CHISTORY.TXT"
remote_dir="EVENTS"
temp_dir_path="temp_dir.XXXXXX"

# Create a temporary directory to store the CHISTORY.TXT file
temp_dir=$(mktemp -d $temp_dir_path)

# Remove temporary directory on exit
trap 'rm -rf "$temp_dir"' EXIT

# Connect to meter and get CHISTORY.TXT
lftp -u "$USERNAME,$PASSWORD" "$meter_ip" <<EOF
set xfer:clobber on
cd $remote_dir
lcd $temp_dir
mget $remote_filename
bye
EOF

# Check the exit status of lftp command
if [ $? -eq 0 ]; then
    log "lftp session successful for: $(basename "$0")"
else
    log "lftp session failed for: $(basename "$0")" "err"
    exit 1
fi

# Path to CHISTORY.TXT in the temporary directory
temp_file_path="$temp_dir/$remote_filename"

# Check if CHISTORY.TXT exists and is not empty
if [ ! -f "$temp_file_path" ] || [ ! -s "$temp_file_path" ]; then
    log "Download failed: $remote_filename. Could not find file: $temp_file_path" "err"
    exit 1
fi

# Initialize a flag to indicate the success of the entire loop process
loop_success=true

# Parse CHISTORY.TXT starting from line 4
awk 'NR > 3' "$temp_file_path" | while IFS= read -r line; do
    # Remove quotes and then extract fields
    clean_line=$(echo "$line" | sed 's/"//g')
    IFS=, read -r _ event_id month day year hour min sec _ <<<"$clean_line"

    if [[ $event_id =~ ^[0-9]+$ ]]; then
        # Format event timestamp, pad month for date directory, and construct event directory path.
        event_timestamp=$(printf '%04d-%02d-%02dT%02d:%02d:%02d' "$year" "$month" "$day" "$hour" "$min" "$sec")
        formatted_month=$(printf '%02d' "$month")
        date_dir="$year-$formatted_month"
        event_dir_path="$output_dir/$date_dir/$meter_id/$event_id"

        # Check if the event directory exists and has all the files
        if [ -d "$event_dir_path" ]; then
            log "Event directory found: $event_id"
            non_empty_files_count=$(find "$event_dir_path" -type f ! -empty -print | wc -l)

            if [ "$non_empty_files_count" -eq $files_per_event ]; then
                log "Complete directory for event: $event_id"

            elif [ "$non_empty_files_count" -ne 0 ]; then
                #TODO: Handle this case
                log "Directoy exists, incomplete event: $event_id" "warn"
            fi

        else
            log "No event directory found, proceeding to download event: $event_id"

            # Output the event_id and date_dir back to download.sh to parse through
            echo "$event_id,$date_dir,$event_timestamp"
        fi

    else
        log "Skipping line: $line, not entirely numeric. Check parsing." "err"
        loop_success=false
        
    fi
    
done

# After the loop, check the flag and log accordingly
if [ "$loop_success" = true ]; then
  echo "Successfully processed all events."
  log "Successfully processed all events."
else
  echo "Finished processing with some errors. Check logs for more information."
  log "Finished processing with some errors." "err"
fi


