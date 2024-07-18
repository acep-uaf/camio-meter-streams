#!/bin/bash
# ==============================================================================
# Script Name:        zip_event.sh
# Description:        This script zips the event files in the source directory
#                     and saves the zip file in the destination directory and removes
#                     the files in the source directory, but leaves the directory to
#                     be used to compare with the history file.
#
# Usage:              ./zip_event.sh <source_dir> <dest_dir> <event_id> <zip_filename>
# Called by:          download.sh
#
# Arguments:
#   source_dir        The directory containing the event files
#   dest_dir          The directory where the zip file will be saved
#   event_id          The event ID (ex.10000)
#   zip_filename      The name of the zip file (ex. location-dataType-meterId-YYYYMM-eventId.zip)
#
# Requirements:       zip
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check for exactly 4 arguments
[ "$#" -ne 4 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <source_dir> <dest_dir> <event_id> <zip_filename>"

source_dir="$1"
dest_dir="$2"
event_id="$3"
zip_filename="$4"

[[ -d "$source_dir/$event_id" ]] || failure $STREAMS_DIR_NOT_FOUND "Source directory does not exist: $source_dir/$event_id"

# Zip the files in the source directory
pushd "$source_dir" > /dev/null
zip -r -q "${dest_dir}/${zip_filename}" $event_id && log "Zipped files for event: $event_id" || failure $STREAMS_ZIP_FAIL "Failed to zip event: $event_id in directory: $source_dir"
popd > /dev/null

# Delete the files in the event_id directory but not the directory itself
find "$source_dir/$event_id" -type f -delete && log "Deleted files in event directory: $source_dir/$event_id" || failure $STREAMS_UNKNOWN "Failed to delete files in event directory: $source_dir/$event_id"
