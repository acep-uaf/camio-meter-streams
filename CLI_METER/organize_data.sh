# After downloading is complete and up to data 
# this file does the following: 
# 1. creates metadata 
# 2. checksum/md5sum
######################################################
#!/bin/bash

EVENT_ID=$1
METER_TIMESTAMP=$2
OTDEV_TIMESTAMP=$3 

log "event id $EVENT_ID" 
log "meter timestamp $METER_TIMESTAMP"
log "downloand from meter to ot dev $OTDEV_TIMESTAMP"


# Base directory where the event files are located
EVENT_DIR="$LOCAL_PATH/$FTP_METER_ID/level0/$EVENT_ID"
log "current event dir: $EVENT_DIR"


# Loop through each file in the event directory
for file in "$EVENT_DIR"/*; do
    if [ -f "$file" ]; then
        # Compute checksum once here
        checksum=$(md5sum "$file" | awk '{ print $1 }')

        # Pass the file and checksum to both metadata creation functions
        source create_metadata_txt.sh "$file" "$checksum" "$EVENT_DIR"
        source create_metadata_json.sh "$file" "$checksum" "$EVENT_DIR"

        # Store the checksum in a separate file with the same name plus .md5 extension
        filename=$(basename "$file")
        echo "$checksum" > "$EVENT_DIR/${filename}.md5"
    else
        echo "No file found for $file"
    fi
done

echo "Metadata and checksums created for files in $EVENT_DIR."

