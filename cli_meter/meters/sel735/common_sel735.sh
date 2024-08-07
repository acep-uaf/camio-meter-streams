#!/bin/bash
# ==============================================================================
# Script Name:        common_sel735.sh
# Description:        Common utility functions for SEL-735 scripts in the Meter Event Data Pipeline.
#
# Functions:
#   handle_sig                  - Handles signals and marks the current event as incomplete
#   mark_event_incomplete       - Marks an event as incomplete and rotates older incomplete directories
#   validate_download           - Validates if all files for an event have been downloaded
#   validate_complete_directory - Validates if the directory is complete
#   generate_date_dir           - Generates a formatted date directory name
#   calculate_max_date          - Calculates the maximum allowable date based on the specified age in days
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
    else
        log "No download in progress, no event to move to .incomplete"
    fi

    source "$current_dir/cleanup_incomplete.sh" "$base_output_dir"

    case $sig in
        SIGINT)
            failure $STREAMS_SIGINT "SIGINT received, exiting"
            ;;
        SIGQUIT)
            failure $STREAMS_SIGQUIT "SIGQUIT received, exiting"
            ;;
        SIGTERM)
            failure $STREAMS_SIGTERM "SIGTERM received, exiting"
            ;;
        *)
            failure $STREAMS_UNKNOWN "Unknown signal received, exiting"
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
    log "Moved event $event_id to ${event_id}.incomplete_${suffix}"
  else
    warning $STREAMS_DIR_NOT_FOUND "Directory $original_dir does not exist" 
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

get_total_event_files_size() {
    local event_dir=$1
    local event_id=$2
    local total_size=0

    # Files expected to have downloaded
    local expected_files=("CEV_${event_id}.CEV" "HR_${event_id}.CFG" "HR_${event_id}.DAT" "HR_${event_id}.HDR" "HR_${event_id}.ZDAT")

    for file in "${expected_files[@]}"; do
        if [ -f "${event_dir}/${file}" ]; then
            file_size=$(stat -c %s "${event_dir}/${file}")
            total_size=$((total_size + file_size))
        fi
    done

    # Convert to KB
    total_files_size_kb=$(echo "scale=4; $total_size / 1024" | bc)
    echo "$total_files_size_kb"
}
# Wrapper function to validate the complete directory
validate_complete_directory() {
    local event_dir=$1
    local event_id=$2

    [ -d "$event_dir" ] || failure $STREAMS_DIR_NOT_FOUND "Directory does not exist: $event_dir"

    # Check for metadata files
    local metadata_files=("${event_id}_metadata.yml" "checksum.md5")
    for file in "${metadata_files[@]}"; do
        log "Checking for metadata file: ${file}"
        if [ ! -f "${event_dir}/${file}" ]; then
            log "Missing metadata file: ${file} in directory: ${event_dir}"
            mark_event_incomplete "$event_id" "$(dirname "$event_dir")" && return 1 # False - Metadata file is missing
        fi
    done

    return 0 # True - All files are present
}

# Function to generate date directory name
generate_date_dir() {
    local year=$1
    local month=$2
    
    formatted_month=$(printf '%02d' "$month")
    date_dir="$year-$formatted_month"
    echo "$date_dir"
}

# Function to calculate the max allowable date
calculate_max_date() {
    local max_age_days=$1
    max_date=$(date -d "$max_age_days days ago" '+%Y-%m-%d')
    echo "$max_date"
}