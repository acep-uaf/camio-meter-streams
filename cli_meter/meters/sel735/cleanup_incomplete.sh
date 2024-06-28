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
source "$(dirname "$0")/../../commons.sh"

# Check for exactly 1 argument
[[ "$#" -ne 1 ]] && fail "Usage: $0 <directory>"

base_directory="$1"

# Check if base_directory exists
[ -d "$base_directory" ] || fail "Base directory does not exist."

# Start cleanup process
log "Starting cleanup process in directory: $base_directory"

# Find and delete all directories matching the pattern *.incomplete_<digit>
find "$base_directory" -type d -regex '.*/.*\.incomplete_[0-9]+' -print0 | while IFS= read -r -d '' dir; do
  rm -rf "$dir" && log "Successfully deleted $dir" || log "Failed to delete $dir"
done

log "Cleanup process completed."
