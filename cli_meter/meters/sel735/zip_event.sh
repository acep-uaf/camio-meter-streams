#!/bin/bash
# ==============================================================================
# Script Name:        zip_event.sh
# Description:        This script zips the event files in the source directory
#                     and saves the zip file in the destination directory.
#
# Usage:              ./zip_event.sh <source_dir> <dest_dir> <event_id>
# Called by:          download.sh
#
# Arguments:
#   source_dir        The directory containing the event files
#   dest_dir          The directory where the zip file will be saved
#   event_id          The event ID (ex.10000)
#
# Requirements:       zip
#                     commons.sh
# ==============================================================================

# Check for exactly 3 arguments
[ "$#" -ne 3 ] && fail "Usage: $0 <source_dir> <dest_dir> <event_id>"

source_dir="$1"
dest_dir="$2"
event_id="$3"

# Zip the files in the source directory
pushd "$source_dir" > /dev/null
zip -r -q "${dest_dir}/${event_id}.zip" $event_id && log "Zipped files for event: $event_id" || fail "Error zipping files for $event_id"
popd > /dev/null
