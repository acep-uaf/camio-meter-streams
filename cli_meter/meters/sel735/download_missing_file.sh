#!/bin/bash

#################################
# This file downloads missing files in event id dir
#
#################################
# This script is called from update_event_files.sh and accepts 2 arguments:
# 1. full path to the local event_id directory
# 2. event_id
#################################

# Define expected filename patterns: PREFIX_eventid.EXTENSION
declare -A file_patterns
file_patterns=(["CEV"]=".CEV" ["HR"]=".CFG .DAT .HDR .ZDAT")

FULL_PATH_EVENT_DIR=$1
EVENT_ID=$2

# Loop through the file patterns array
for prefix in "${!file_patterns[@]}"; do

    # Split the extensions for the current prefix
    IFS=' ' read -r -a extensions <<<"${file_patterns[$prefix]}"

    for extension in "${extensions[@]}"; do
        # Construct the expected filename
        expected_file_path="${FULL_PATH_EVENT_DIR}/${prefix}_${EVENT_ID}${extension}"

        # Check if the file exists
        if [ ! -f "$expected_file_path" ]; then
            missing_file=${prefix}_${EVENT_ID}${extension}
            log "Downloading missing file: $missing_file"

            # Start an lftp session to download the missing file
            lftp -u "$USERNAME,$PASSWORD" "$METER_IP" <<EOF
            
            set xfer:clobber on
            cd $FTP_REMOTE_METER_PATH
            lcd $FULL_PATH_EVENT_DIR
            mget $missing_file
            bye
EOF

            # Check if the file was successfully downloaded
            if [ -f "$expected_file_path" ] && [ -s "$expected_file_path" ]; then
                # Compute checksum here, ensuring the file exists
                checksum=$(md5sum "$expected_file_path" | awk '{ print $1 }')

                # Source and check create_metadata_txt.sh
                source create_metadata_txt.sh "$expected_file_path" "$checksum" "$FULL_PATH_EVENT_DIR"
                if [ $? -ne 0 ]; then
                    log "create_metadata_txt.sh failed for: $expected_file_path" "err"
                fi

                # Source and check create_metadata_json.sh
                source create_metadata_json.sh "$expected_file_path" "$checksum" "$FULL_PATH_EVENT_DIR"
                if [ $? -ne 0 ]; then
                    log "create_metadata_json.sh failed for: $expected_file_path" "err"
                fi

                # Store the checksum in a separate file with the same name plus .md5 extension
                filename=$(basename "$expected_file_path")
                log "Metadata and checksums created for: $filename"
                echo "$checksum" >"$EVENT_DIR/${filename}.md5"
            else
                log "Failed to download $expected_file_path" "err"
            fi
        fi
    done
done
