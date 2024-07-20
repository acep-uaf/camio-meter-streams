#!/bin/bash
# ==============================================================================
# Script Name:        generate_and_create_metadata.sh
# Description:        This script creates metadata for the specified event files
#                     using environment variables and outputs it in YML format.
#
# Usage:              ./generate_and_create_metadata.sh <event_id> <event_dir> <meter_id>
#                     <meter_type> <event_timestamp> <download_start> <download_end>
#
# Arguments:
#   event_id          Event ID
#   event_dir         Directory where the event files are stored
#   meter_id          Meter ID
#   meter_type        Meter type
#   event_timestamp   Original timestamp of the event
#   download_start    Timestamp of when the download started
#   download_end      Timestamp of when the download ended
#
# Requirements:       common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check if the correct number of arguments are passed
[ "$#" -ne 7 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <event_id> <event_dir> <meter_id> <meter_type> <event_timestamp> <download_start> <download_end>"

event_id=$1
event_dir="$2/$event_id" # Assumes location/data_type/working/YYYY-MM/meter_id/event_id
meter_id=$3
meter_type=$4
event_timestamp=$5
download_start=$6
download_end=$7

metadata_file="${event_id}_metadata.yml"
metadata_path="$event_dir/$metadata_file"
checksum_file="$event_dir/checksum.md5"

# Initialize metadata
{
    echo "event_id: \"$event_id\""
    echo "event_timestamp: \"$event_timestamp\""
    echo "meter_id: \"$meter_id\""
    echo "meter_type: \"$meter_type\""
    echo "data_level: \"level0\""
    echo "download_start: \"$download_start\""
    echo "download_end: \"$download_end\""
    echo "download_time: \"\""
    echo "download_speed: \"\""
    echo "total_files_size: \"\""
    echo ""
    echo "files:"
} > "$metadata_path" && log "Initialized metadata file: $metadata_path"

log "Creating metadata for event: $event_id"

total_files_size=0

for file in "$event_dir"/*; do
    filename=$(basename "$file")
    if [ -s "$file" ]; then
        # Skip if the file is a metadata file
        if [[ "$file" == *_metadata.yml ]]; then
            log "Skipping metadata creation for: $filename"
            continue
        fi
        checksum=$(md5sum "$file" | awk '{print $1}')
        echo "$checksum $filename" >> "$checksum_file" && log "Checksum generated and added to checksum.md5 for file: $filename"

        # Append file metadata to the main metadata file
        file_size=$(stat -c%s "$file")
        total_files_size=$((total_files_size + file_size))

        {
            echo "  - file_name: $filename"
            echo "    md5: \"$checksum\""
        } >> "$metadata_path" && log "Metadata generated for: $filename" || failure $STREAMS_FILE_CREATION_FAIL "Failed to generate metadata for: $filename"
    else
        failure $STREAMS_FILE_NOT_FOUND "File not found or is empty: $file"
    fi
done

# Calculate download_time and download_speed
download_time=$(($(date -d "$download_end" +%s) - $(date -d "$download_start" +%s)))
download_speed=$(echo "scale=2; $total_files_size / $download_time" | bc)
log "Download start: $download_start"
log "Download end: $download_end"
log "Total files size: $total_files_size bytes"
log "Download time: $download_time seconds"
log "Download speed: $download_speed bytes/second"

# Append calculated fields to metadata
sed -i "s/download_time: \"\"/download_time: \"$download_time seconds\"/" "$metadata_path"
sed -i "s/download_speed: \"\"/download_speed: \"$download_speed bytes\/second\"/" "$metadata_path"
sed -i "s/total_files_size: \"\"/total_files_size: \"$total_files_size bytes\"/" "$metadata_path"

log "Final metadata appended to: $metadata_path"
