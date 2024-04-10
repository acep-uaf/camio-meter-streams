handle_sigint() {
    # Mark event incomplete if event_id is set
    if [ -n "$current_event_id" ]; then
        local output_dir="$base_output_dir/$date_dir/$meter_id"
        mark_event_incomplete "$current_event_id" "$output_dir"
    else
        log "current_event_id is not set, no event to move to .incomplete."
    fi

}

# Mark event as incomplete
mark_event_incomplete() {
  local event_id="$1"
  local original_dir="$2/$event_id"
  
  # Initialize the base name for incomplete directories
  local base_incomplete_dir="${original_dir}.incomplete"

  # Check if the original directory exists
  if [ -d "$original_dir" ]; then
    # Find an available suffix or the one to rotate
    local suffix=1
    while [ -d "${base_incomplete_dir}_${suffix}" ]; do
      let suffix++
      # If reaching the 6th iteration, start rotation from 1
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
        if [ ! -f "${event_dir}/${file}" ]; then
            return 0 # File is missing
        fi
    done
    return 1 # All files are present
}
