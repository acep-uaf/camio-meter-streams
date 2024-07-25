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
    echo "duration: \"\""
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

# Calculate duration and download_speed
duration=$(($(date -d "$download_end" +%s) - $(date -d "$download_start" +%s)))

[[ "$duration" -eq 0 ]] && duration=1 && log "Download time is zero, setting it to 1 second"
[[ "$total_files_size" -eq 0 ]] && log "Total files size is zero, setting it to 1 byte" && total_files_size=1

# Convert bytes to kilobytes and round to 2 decimal places
total_files_size_kb=$(echo "scale=4; $total_files_size / 1024" | bc)
download_speed_kbps=$(echo "scale=4; $total_files_size_kb / $duration" | bc)

total_files_size_fmt=$(numfmt --to=iec --suffix=B --format="%.4f" "$total_files_size_kb")
download_speed_fmt=$(numfmt --to=iec --suffix=Bps --format="%.4f" "$download_speed_kbps")

log "Download start: $download_start"
log "Download end: $download_end"
log "Total files size: $total_files_size_fmt"
log "Download duration: ${duration}s"
log "Download speed: $download_speed_fmt"

# Append calculated fields to metadata
sed -i "s/duration: \"\"/duration: \"${duration}s\"/" "$metadata_path"
sed -i "s/download_speed: \"\"/download_speed: \"$download_speed_fmt\"/" "$metadata_path"
sed -i "s/total_files_size: \"\"/total_files_size: \"$total_files_size_fmt\"/" "$metadata_path"

log "Final metadata appended to: $metadata_path"
