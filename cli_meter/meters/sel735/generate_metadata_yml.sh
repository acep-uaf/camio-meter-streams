#!/bin/bash
# ==============================================================================
# Script Name:        generate_and_create_metadata.sh
# Description:        This script creates metadata for the specified event files
#                     using environment variables and outputs it in YML format.
#
# Usage:              ./generate_and_create_metadata.sh <event_id> <event_dir> <meter_id>
#                     <meter_type> <event_timestamp> <started_at> <completed_at>
#
# Arguments:
#   event_id          Event ID
#   event_dir         Directory where the event files are stored
#   meter_id          Meter ID
#   meter_type        Meter type
#   event_timestamp   Original timestamp of the event
#   started_at    Timestamp of when the download started
#   completed_at      Timestamp of when the download ended
#
# Requirements:       common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"
source "$current_dir/common_sel735.sh"

# Check if the correct number of arguments are passed
[ "$#" -ne 7 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <event_id> <event_dir> <meter_id> <meter_type> <event_timestamp> <started_at> <completed_at>"

event_id=$1
event_dir="$2/$event_id" # Assumes location/data_type/working/YYYY-MM/meter_id/event_id
meter_id=$3
meter_type=$4
event_timestamp=$5
started_at=$6
completed_at=$7

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
    echo "started_at: \"$started_at\""
    echo "completed_at: \"$completed_at\""
    echo "duration: \"\""
    echo "download_size: \"\""
    echo "download_speed: \"\""
    echo ""
    echo "files:"
} > "$metadata_path" && log "Initialized metadata file: $metadata_path"

log "Creating metadata for event: $event_id"

for file in "$event_dir"/*; do
    filename=$(basename "$file")
    if [ -s "$file" ]; then
        # Skip if the file is a metadata file or the checksum file
        if [[ "$filename" == *_metadata.yml || "$filename" == "checksum.md5" ]]; then
            log "Skipping metadata creation for: $filename"
            continue
        fi
        checksum=$(md5sum "$file" | awk '{print $1}')
        echo "$checksum $filename" >> "$checksum_file" && log "Checksum generated and added to checksum.md5 for file: $filename"

        # Append file metadata to the main metadata file
        {
            echo "  - file_name: $filename"
            echo "    md5: \"$checksum\""
        } >> "$metadata_path" && log "Metadata generated for: $filename" || failure $STREAMS_FILE_CREATION_FAIL "Failed to generate metadata for: $filename"
    else
        failure $STREAMS_FILE_NOT_FOUND "File not found or is empty: $file"
    fi
done

# Calculate duration and download_speed
duration=$(($(date -d "$completed_at" +%s) - $(date -d "$started_at" +%s)))
[[ "$duration" -eq 0 ]] && duration=1 && log "Download time is zero, setting it to 1 second"

download_size_kb=$(get_total_event_files_size "$event_dir" "$event_id")
is_zero=$(echo "$download_size_kb <= 0" | bc)
[[ "$is_zero" -eq 1 ]] && log "Total files size is zero, setting it to 1 kilobyte" && download_size_kb=1

download_speed_kbps=$(echo "scale=4; $download_size_kb / $duration" | bc)
log "Calculated metadata for event: $event_id"
log "Download size: ${download_size_kb}KB"
log "Download duration: ${duration}s"
log "Download speed: ${download_speed_kbps}KBps"

# Append calculated fields to metadata
sed -i "s/duration: \"\"/duration: \"${duration}s\"/" "$metadata_path"
sed -i "s/download_speed: \"\"/download_speed: \"${download_speed_kbps}KBps\"/" "$metadata_path"
sed -i "s/download_size: \"\"/download_size: \"${download_size_kb}KB\"/" "$metadata_path"

log "Final metadata appended to: $metadata_path"
