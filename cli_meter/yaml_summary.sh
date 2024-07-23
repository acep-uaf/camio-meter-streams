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
  echo "meters:" > "$yaml_file"
}

init_meter_summary() {
  local yaml_file=$1
  local meter_name=$2
  local started_at=$3

  meter_template="{
    \"name\": \"$meter_name\",
    \"status\": \"\",
    \"started_at\": \"$started_at\",
    \"completed_at\": \"\"
  }"

  yq e -i ".meters += [$meter_template]" "$yaml_file"
}

append_meter() {
  local yaml_file=$1
  local meter_name=$2
  local status=$3
  local completed_at=$4
  local error_code=$5
  local error_message=$6

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .status) = \"$status\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .completed_at) = \"$completed_at\"" "$yaml_file"
}

append_event() {
  local yaml_file=$1
  local meter_name=$2
  local event_id=$3
  local event_status=$4

  # Add the events array if it doesn't exist
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) = ( .meters[] | select(.name == \"$meter_name\") | .events // [] )" "$yaml_file"

  # Create the event template
  event_template="{
    \"event_id\": \"$event_id\",
    \"status\": \"$event_status\"
  }"

  # Append the event to the specified meter's events array
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) += [$event_template]" "$yaml_file"

}

append_error(){
  local yaml_file=$1
  local meter_name=$2
  local exit_code=$3
  local message=$4

  # Add the errors array if it doesn't exist
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors ) = ( .meters[] | select(.name == \"$meter_name\") | .errors // [] )" "$yaml_file"

  # Create the error template
  error_template="{
    \"exit_code\": \"$exit_code\",
    \"message\": \"$message\"
  }"

  # Append the error to the specified meter's errors array
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors ) += [$error_template]" "$yaml_file"

}

export -f init_summary
export -f init_meter_summary
export -f append_meter
export -f append_event
export -f append_error
