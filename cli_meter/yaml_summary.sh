#!/bin/bash

# ==============================================================================
# Script Name:        log_summary.sh
# Description:        This script handles the creation and appending of entries
#                     to a summary log file in YAML format.
#
# Operations:
#   init_summary      Initializes the log file
#   append_meter      Appends meter information to the log file
#   append_event      Appends event information to the log file
#
# Arguments for 'init_summary':
#   <yaml_file>       Path to the YAML file to initialize
#
# Arguments for 'append_meter':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <status>          Status of the download (success/failure)
#   <started_at>      Start time of the download
#   <completed_at>    End time of the download
#   <error_code>      Error code (optional)
#   <error_message>   Error message (optional)
#
# Arguments for 'append_event':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <event_id>        ID of the event
#   <event_status>    Status of the event (success/failure)
#   <error_code>      Error code (optional)
#   <error_message>   Error message (optional)
# ==============================================================================

init_summary() {
  local yaml_file=$1
  local dir
  dir=$(dirname "$yaml_file")
  
  # Create the directory if it does not exist
  mkdir -p "$dir"
  
}

init_meter_summary() {
  local yaml_file=$1
  local meter_name=$2
  local started_at=$3
  {
      echo "meters:"
      echo "  - name: $meter_name"
      echo "    status:"
      echo "    warnings:"
      echo "    errors:"
      echo "    events:"
      echo "      total: 0"
      echo "      downloaded: 0"
      echo "      failed: 0"
      echo "    started_at: $started_at"
      echo "    completed_at: "
  } > "$yaml_file"
}

append_meter() {
  local yaml_file=$1
  local meter_name=$2
  local status=$3
  local started_at=$4
  local completed_at=$5
  local error_code=$6
  local error_message=$7

  {
      echo "  - name: $meter_name"
      echo "    status: $status"
      echo "    warnings:"
      echo "    errors:"
      [[ -n "$error_code" && -n "$error_message" ]] && echo "      - code: $error_code"
      [[ -n "$error_message" ]] && echo "        message: $error_message"
      echo "    events:"
      echo "      total: 0"
      echo "      downloaded: 0"
      echo "      failed: 0"
      echo "    started_at: $started_at"
      echo "    completed_at: $completed_at"
  } >> "$yaml_file"
}

append_event() {
  local yaml_file=$1
  local meter_name=$2
  local event_id=$3
  local event_status=$4
  local error_code=$5
  local error_message=$6

  log "Appending event: $event_id for meter: $meter_name"
  log "Event status: $event_status"
  log "Error code: $error_code"
  log "Error message: $error_message"
}

export -f init_summary
export -f init_meter_summary
export -f append_meter
export -f append_event
