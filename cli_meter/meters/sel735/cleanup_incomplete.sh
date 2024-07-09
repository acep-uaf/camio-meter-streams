#!/bin/bash
# ==============================================================================
# Script Name:        cleanup_incomplete.sh
# Description:        This script deletes all directories matching the pattern
#                     *.incomplete_<digit> within a given directory.
#
# Usage:              ./cleanup_incomplete.sh <directory>
#
# Arguments:
#   directory         Path to the base directory to clean up
#
# Requirements:       None
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")
script_name=$(basename "$0")
source "$current_dir/../../common_utils.sh"

# Check for exactly 1 argument
[[ "$#" -ne 1 ]] && failure $STREAMS_INVALID_ARGS "Usage: $script_name <directory>"

base_directory="$1"

# Check if base_directory exists
[ -d "$base_directory" ] && log "Base directory exists" || failure $STREAMS_DIR_NOT_FOUND "Base directory does not exist."

log "Starting cleanup process in directory: $base_directory"

# Find and delete all directories matching the pattern *.incomplete_<digit>
find "$base_directory" -type d -regex '.*/.*\.incomplete_[0-9]+' -print0 | while IFS= read -r -d '' dir; do
  rm -rf "$dir" && log "Successfully deleted directory: $dir" || log "Failed to delete directory: $dir"
done

# Find and delete all empty directories
find "$base_directory" -type d -empty -print0 | while IFS= read -r -d '' dir; do
  rmdir "$dir" && log "Successfully deleted empty directory: $dir" || log "Failed to delete empty directory: $dir"
done

log "Cleanup process completed in directory: $base_directory"
