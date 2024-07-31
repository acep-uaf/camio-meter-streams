#!/bin/bash
# ==============================================================================
# Script Name:        zip_event.sh
# Description:        This script creates a symbolic link for the event directory,
#                     zips the contents via the symbolic link, saves the zip file in the
#                     destination directory, and then removes the symbolic link. It also
#                     removes the files in the source directory but leaves the directory
#                     itself to be used for comparison with the history file.
#
# Usage:              ./zip_event.sh <source_dir> <dest_dir> <event_id> <symlink_name>
# Called by:          download.sh
#
# Arguments:
#   source_dir        The directory containing the event files
#   dest_dir          The directory where the zip file will be saved
#   event_id          The event ID (ex.10000)
#   symlink_name      The name of the symlink and base of the zip file (ex. location-dataType-meterId-YYYYMM-eventId)
#
# Requirements:       zip
#                     common_utils.sh
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check for exactly 4 arguments
[ "$#" -ne 4 ] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <source_dir> <dest_dir> <event_id> <symlink_name>"

source_dir="$1"
dest_dir="$2"
event_id="$3"
symlink_name="$4"
zip_filename="${symlink_name}.zip"

[[ -d "$source_dir/$event_id" ]] || failure $STREAMS_DIR_NOT_FOUND "Source directory does not exist: $source_dir/$event_id"

# Zip the files in the source directory
pushd "$source_dir" > /dev/null
ln -s "$event_id" "$symlink_name" && log "Created symlink: $symlink_name" || failure $STREAMS_SYMLINK_FAIL "Failed to create symlink: $symlink_name"
zip -r -q "${dest_dir}/${zip_filename}" "$symlink_name" && \
log "Successfully zipped symlink: $symlink_name to ${dest_dir}/${zip_filename} for event: $event_id" || \
failure $STREAMS_ZIP_FAIL "Failed to zip symlink: $symlink_name located at ${source_dir}/${symlink_name} to ${dest_dir}/${zip_filename}"
rm "$symlink_name" && log "Removed symlink: $symlink_name" || failure $STREAMS_SYMLINK_FAIL "Failed to remove symlink: $symlink_name"
popd > /dev/null

# Delete the files in the event_id directory but not the directory itself
find "$source_dir/$event_id" -type f -delete && log "Deleted files in event directory: $source_dir/$event_id" || failure $STREAMS_UNKNOWN "Failed to delete files in event directory: $source_dir/$event_id"
