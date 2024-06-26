#!/bin/bash
# ==============================================================================
# Script Name:        commons.sh
# Description:        Common utility functions used across various scripts in
#                     the SEL-735 Meter Event Data Pipeline.
#
# Functions:
#   handle_sigint()       - Handles SIGINT signal and marks the current event as incomplete
#   mark_event_incomplete - Marks an event as incomplete and rotates older incomplete directories
#   validate_download()   - Validates if all files for an event have been downloaded
#
# ==============================================================================
current_dir=$(dirname "$(readlink -f "$0")")

# Function to handle SIGINT (Ctrl+C) and mark event as incomplete
handle_sigint() {
    # Mark event incomplete if event_id is set
    if [ -n "$current_event_id" ]; then
        local output_dir="$base_output_dir/$date_dir/$meter_id"
        mark_event_incomplete "$current_event_id" "$output_dir"
    else
        log "current_event_id is not set, no event to move to .incomplete."
    fi

    source "$current_dir/cleanup_incomplete.sh" "$base_output_dir"
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
        mv "${base_incomplete_dir}_$i" "${base_incomplete_dir}_$((i-1))"
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
        [ ! -f "${event_dir}/${file}" ] && return 0 # File is missing
    done
    return 1 # All files are present
}
