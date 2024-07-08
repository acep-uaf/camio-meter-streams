#!/bin/bash
# ==============================================================================
# Script Name:        common_sel735.sh
# Description:        Common utility functions for SEL-735 scripts in Meter Event Data Pipeline.
#
# Functions:
#   handle_sig                  - Handles signals and marks the current event as incomplete
#   mark_event_incomplete       - Marks an event as incomplete and rotates older incomplete directories
#   validate_download           - Validates if all files for an event have been downloaded
#   validate_complete_directory - Validates if the directory is complete
#
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")

# Function to handle SIGs and calls mark_event_incomplete()
handle_sig() {
    local sig=$1

    # Mark event incomplete if event_id is set
    if [ -n "$current_event_id" ]; then
        local output_dir="$base_output_dir/$date_dir/$meter_id"
        mark_event_incomplete "$current_event_id" "$output_dir"
        log "Download in progress, moving event $current_event_id to .incomplete"
    else
        log "No download in progress, no event to move to .incomplete"
    fi

    source "$current_dir/cleanup_incomplete.sh" "$base_output_dir"

    case $sig in
        SIGINT)
            failure $STREAMS_SIGINT "SIGINT received. Exiting..."
            ;;
        SIGQUIT)
            failure $STREAMS_SIGQUIT "SIGQUIT received. Exiting..."
            ;;
        SIGTERM)
            failure $STREAMS_SIGTERM "SIGTERM received. Exiting..."
            ;;
        *)
            failure $STREAMS_UNKNOWN "Unknown signal received. Exiting..."
            ;;
    esac
}

# Function to mark an event as incomplete and rotate older incomplete directories
mark_event_incomplete() {
  local event_id="$1"
  local original_dir="$2/$event_id"
  
  # Initialize the base name for incomplete directories
  local base_incomplete_dir="${original_dir}.incomplete"

  # Check if the original directory exists
  if [ -d "$original_dir" ]; then
    local suffix=1
    while [ -d "${base_incomplete_dir}_${suffix}" ]; do
      ((suffix++))
      # If we reach 5, we need to rotate the directories
      if [ "$suffix" -gt 5 ]; then
        suffix=5
        break
      fi
    done

    # Remove the oldest if going to exceed 5 directories
    if [ -d "${base_incomplete_dir}_5" ]; then
      rm -rf "${base_incomplete_dir}_1"
      # Shift remaining directories
      for ((i=2; i<=5; i++)); do
        mv "${base_incomplete_dir}_$i" "${base_incomplete_dir}_$((i-1))" && log "Rotated ${base_incomplete_dir}_$i to ${base_incomplete_dir}_$((i-1))"
      done
    fi

    # Move the current directory to its new incomplete name
    mv "$original_dir" "${base_incomplete_dir}_${suffix}"
    log "" # Add a new line for better readability
    log "Moved event $event_id to ${event_id}.incomplete_${suffix}"
  else
    log "[ERROR] Directory $original_dir does not exist."
  fi
}

# Function to check if all files for an event have been downloaded
validate_download() {
    local event_dir=$1
    local event_id=$2
    # Files expect to have downloaded
    local expected_files=("CEV_${event_id}.CEV" "HR_${event_id}.CFG" "HR_${event_id}.DAT" "HR_${event_id}.HDR" "HR_${event_id}.ZDAT")
    for file in "${expected_files[@]}"; do
        [ ! -f "${event_dir}/${file}" ] && log "Missing file: ${file} in directory: ${event_dir}" && return 1 # False - File is missing
    done
    return 0 # True - All files are present
}

# Wrapper function to validate the complete directory
validate_complete_directory() {
    local event_dir=$1
    local event_id=$2

    [ -d "$event_dir" ] || return 1 # False - Directory does not exist

    # Validate event files
    validate_download "$event_dir" "$event_id" || return 1

    # Check for metadata files
    local metadata_files=("${event_id}_metadata.yml" "checksum.md5")
    for file in "${metadata_files[@]}"; do
        [ ! -f "${event_dir}/${file}" ] && log "Missing metadata file: ${file} in directory: ${event_dir}" && return 1 # False - Metadata file is missing
    done

    return 0 # True - All files are present
}
