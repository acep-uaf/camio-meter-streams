#!/bin/bash
##############################
# this file downloads missing 
# files in event id dir
##############################

LOG_FILE="download_missing_file.log"

# Define expected filename patterns: PREFIX_eventid.EXTENSION
declare -A file_patterns
file_patterns=(["CEV"]=".CEV" ["HR"]=".CFG .DAT .HDR .ZDAT")

FULL_PATH_EVENT_DIR=$1 
EVENT_ID=$2

# Loop through the file patterns array
for prefix in "${!file_patterns[@]}"; do
    # Split the extensions for the current prefix
    IFS=' ' read -r -a extensions <<< "${file_patterns[$prefix]}"
    for extension in "${extensions[@]}"; do
        # Construct the expected filename
        expected_file="${FULL_PATH_EVENT_DIR}/${prefix}_${EVENT_ID}${extension}"

        log "expected file $expected_file" "WARNING" "$LOG_FILE"

        # Check if the file exists
        if [ ! -f "$expected_file" ]; then
            log "Missing file: $expected_file, attempting to download..." "INFO" "$LOG_FILE"

            file=${prefix}_${EVENT_ID}${extension}
            # Start an lftp session to download the missing file
            lftp -u "$FTP_METER_USER,$FTP_METER_USER_PASSWORD" "$FTP_METER_SERVER_IP" <<EOF
            
set xfer:clobber on
cd $FTP_REMOTE_METER_PATH
lcd $FULL_PATH_EVENT_DIR
mget $file
bye
EOF
        fi

        # Check if the file was successfully downloaded
        if [ -f "$expected_file" ]; then
            # Compute checksum here, ensuring the file exists
            checksum=$(md5sum "$expected_file" | awk '{ print $1 }')
            # Call the script to create metadata, passing the necessary arguments
            source create_metadata_json.sh "$expected_file" "$checksum" "$FULL_PATH_EVENT_DIR"
            
            # Store the checksum in a separate file with the same name plus .md5 extension
            filename=$(basename "$file")
            echo "$checksum" > "$EVENT_DIR/${filename}.md5"
        else
            log "Failed to download $expected_file" "ERROR" "$LOG_FILE"
        fi
    done
done