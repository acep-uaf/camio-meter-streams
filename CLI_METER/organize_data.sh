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

create_metadata_txt() {
    local file=$1
    local checksum=$2  # Accept checksum as an argument
    local filename=$(basename "$file")
    local metadata_file="$EVENT_DIR/${EVENT_ID}_metadata.txt"

    echo "Creating/Writing to $metadata_file for $file"
    {
        echo "File: $filename"
        echo "DownloadedAt: $OTDEV_TIMESTAMP"
        echo "MeterEventDate: $METER_TIMESTAMP"
        echo "MeterID: $FTP_METER_ID"
        echo "EventID: $EVENT_ID"
        echo "DataLevel: Level0"
        echo "Checksum: $checksum"  # Include the checksum in the metadata
        echo "----"
    } >> "$metadata_file"
}

create_metadata_json() {
    local file=$1
    local checksum=$2  # Accept checksum as an argument
    local filename=$(basename "$file")
    local metadata_file="$EVENT_DIR/${EVENT_ID}_metadata.json"

    # Check if the metadata JSON file already exists, if not create an empty array
    if [ ! -f "$metadata_file" ]; then
        echo '[]' > "$metadata_file"
    fi

    # Read the existing JSON data, add the new entry with the checksum, and write back to the file
    jq --arg file "$filename" \
       --arg downloadedAt "$OTDEV_TIMESTAMP" \
       --arg meterEventDate "$METER_TIMESTAMP" \
       --arg meterID "$FTP_METER_ID" \
       --arg eventID "$EVENT_ID" \
       --arg dataLevel "Level0" \
       --arg checksum "$checksum" \
       '. += [{
         File: $file,
         DownloadedAt: $downloadedAt,
         MeterEventDate: $meterEventDate,
         MeterID: $meterID,
         EventID: $eventID,
         DataLevel: $dataLevel,
         Checksum: $checksum
       }]' "$metadata_file" > "tmp.$$.json" && mv "tmp.$$.json" "$metadata_file"
}

# Loop through each file in the event directory
for file in "$EVENT_DIR"/*; do
    if [ -f "$file" ]; then
        # Compute checksum once here
        checksum=$(md5sum "$file" | awk '{ print $1 }')

        # Pass the file and checksum to both metadata creation functions
        create_metadata_txt "$file" "$checksum"
        create_metadata_json "$file" "$checksum"

        # Store the checksum in a separate file with the same name plus .md5 extension
        filename=$(basename "$file")
        echo "$checksum" > "$EVENT_DIR/${filename}.md5"
    else
        echo "No file found for $file"
    fi
done

echo "Metadata and checksums created for files in $EVENT_DIR."

