#!/bin/bash

# ==============================================================================
# Script Name:        log_summary.sh
# Description:        This script handles the creation and appending of entries
#                     to a summary log file in YAML format.
#
# Operations:
#   init_summary      Initializes the log file
#   init_meter_summary Initializes a meter entry in the log file
#   append_info       Appends general information to the log file
#   append_meter      Appends meter completion information to the log file
#   append_event      Appends event information to the log file
#   append_error      Appends error information to the log file
#   append_timestamps Appends start and end timestamps with duration calculation
#   calculate_duration Calculates the duration between two timestamps
#
# Arguments for 'init_summary':
#   <yaml_file>       Path to the YAML file to initialize
#   <started_at>      Start time of the download
#
# Arguments for 'init_meter_summary':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <started_at>      Start time of the meter download
#
# Arguments for 'append_info':
#   <yaml_file>       Path to the YAML file
#   <key>             Key to append
#   <value>           Value to append
#
# Arguments for 'append_meter':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <status>          Status of the download (success/failure)
#   <completed_at>    End time of the download
#
# Arguments for 'append_event':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <event_id>        ID of the event
#   <event_status>    Status of the event (success/failure)
#
# Arguments for 'append_error':
#   <yaml_file>       Path to the YAML file
#   <meter_name>      Name of the meter
#   <exit_code>       Exit code of the error
#   <message>         Error message
#
# Arguments for 'append_timestamps':
#   <yaml_file>       Path to the YAML file
#   <started_at>      Start time
#   <completed_at>    End time
#   <type>            Type (e.g., download or meter)
# ==============================================================================


init_summary() {
  local yaml_file=$1
  local started_at=$2
  local dir=$(dirname "$yaml_file")
  mkdir -p "$dir"


  echo "download:" >> "$yaml_file"
  echo "  started_at: \"$started_at\"" >> "$yaml_file"
  echo "  completed_at: \"\"" >> "$yaml_file"
  echo "  duration: \"\"" >> "$yaml_file"
  echo "meters:" >> "$yaml_file"
  
}

init_meter_summary() {
  local yaml_file=$1
  local meter_name=$2
  local started_at=$3

  meter_template="{
    \"name\": \"$meter_name\",
    \"status\": \"\",
    \"started_at\": \"$started_at\",
    \"completed_at\": \"\",
    \"duration\": \"\"
  }"

  yq e -i ".meters += [$meter_template]" "$yaml_file"
}

append_info() {
  local yaml_file=$1
  local key=$2
  local value=$3

  yq e -i ".${key} = \"$value\"" "$yaml_file"
}

append_meter() {
  local yaml_file=$1
  local meter_name=$2
  local status=$3
  local started_at=$4
  local completed_at=$5

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .status) = \"$status\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .completed_at) = \"$completed_at\"" "$yaml_file"

  started_at=$(yq e ".meters[] | select(.name == \"$meter_name\") | .started_at" "$yaml_file")

  duration=$(calculate_duration "$started_at" "$completed_at")
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .duration) = \"$duration\"" "$yaml_file"

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
append_timestamps() {
  local yaml_file=$1
  local started_at=$2
  local completed_at=$3
  local type=$4

  yq e -i ".$type.started_at = \"$started_at\"" "$yaml_file"
  yq e -i ".$type.completed_at = \"$completed_at\"" "$yaml_file"

  duration=$(calculate_duration "$started_at" "$completed_at")
  yq e -i ".$type.duration = \"$duration\"" "$yaml_file"

}

calculate_duration() {
  local started_at=$1
  local completed_at=$2

  start_seconds=$(date -d "$started_at" +%s)
  end_seconds=$(date -d "$completed_at" +%s)

  duration=$((end_seconds - start_seconds))
  echo $duration
}

export -f init_summary
export -f init_meter_summary
export -f append_meter
export -f append_event
export -f append_error
export -f append_timestamps
