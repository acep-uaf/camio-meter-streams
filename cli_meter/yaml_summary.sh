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
  local meters_total=$3
  local dir=$(dirname "$yaml_file")
  mkdir -p "$dir"

  echo "summary:" >> "$yaml_file"
  echo "  started_at: \"$started_at\"" >> "$yaml_file"
  echo "  completed_at: \"\"" >> "$yaml_file"
  echo "  duration: \"\"" >> "$yaml_file"
  echo "  meters_total: $meters_total" >> "$yaml_file"
  echo "  meters_attempted: 0" >> "$yaml_file"
  echo "  meters_successful: 0" >> "$yaml_file"
  echo "  meters_failed: 0" >> "$yaml_file"
  echo "meters:" >> "$yaml_file"
  
}

init_meter_summary() {
  local yaml_file=$1
  local meter_name=$2
  local started_at=$3

  meter_template="{
    \"name\": \"\",
    \"status\": \"\",
    \"started_at\": \"\",
    \"completed_at\": \"\",
    \"duration\": \"\",
    \"downloads\": {
      \"total\": 0,
      \"success\": 0,
      \"fail\": 0,
      \"skipped\": 0
    },
    \"events\": []
  }"

  yq e -i ".meters += [$meter_template]" "$yaml_file"

  # Insert the meter name and start time
  yq e -i "( .meters[] | select(.name == \"\") | .name ) = \"$meter_name\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .started_at ) = \"$started_at\"" "$yaml_file"
}

init_event_summary() {
  local yaml_file=$1
  local meter_name=$2
  local total_events=$3

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.total ) = $total_events" "$yaml_file"
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

  duration=$(calculate_duration $started_at $completed_at)
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .duration) = \"${duration}s\"" "$yaml_file"

}

append_event() {
  local yaml_file=$1
  local meter_name=$2
  local event_id=$3
  local event_status=$4
  local started_at=$5
  local completed_at=$6
  local total_files_size=$7
  local exit_code=${8:-}
  local message=${9:-}

  # Add the events array if it doesn't exist
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) = ( .meters[] | select(.name == \"$meter_name\") | .events // [] )" "$yaml_file"

  if [ "$event_status" == "failure" ]; then
    event_template="{
      \"event_id\": $event_id,
      \"status\": \"\",
      \"started_at\": \"\",
      \"completed_at\": \"\",
      \"duration\": \"\",
      \"download_size\": \"\",
      \"download_speed\": \"\",
      \"exit_code\": $exit_code,
      \"message\": \"\"
    }"
  else
    event_template="{
      \"event_id\": $event_id,
      \"status\": \"\",
      \"started_at\": \"\",
      \"completed_at\": \"\",
      \"duration\": \"\",
      \"download_size\": \"\",
      \"download_speed\": \"\"
    }"
  fi

  duration=$(calculate_duration "$started_at" "$completed_at")

  [ "$duration" -eq 0 ] && duration=1
  download_speed=$(echo "scale=4; $total_files_size / $duration" | bc)
  # Append the event to the specified meter's events array
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) += [$event_template]" "$yaml_file"

  # Insert status into the event template
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].status ) = \"$event_status\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].started_at ) = \"$started_at\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].completed_at ) = \"$completed_at\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].duration ) = \"${duration}s\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].download_size ) = \"${total_files_size}KB\"" "$yaml_file"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].download_speed ) = \"${download_speed}KBps\"" "$yaml_file"

  if [ "$event_status" == "success" ]; then
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.success ) |= . + 1" "$yaml_file"
  else
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.fail ) |= . + 1" "$yaml_file"
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].message ) = \"$message\"" "$yaml_file"
  fi
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
    \"exit_code\": $exit_code,
    \"message\": \"\"
  }"

  # Append the error to the specified meter's errors array
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors ) += [$error_template]" "$yaml_file"
  
  # Insert message into the error template
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors[-1].message ) = \"$message\"" "$yaml_file"

}
append_timestamps() {
  local yaml_file=$1
  local started_at=$2
  local completed_at=$3
  local type=$4

  yq e -i ".$type.started_at = \"$started_at\"" "$yaml_file"
  yq e -i ".$type.completed_at = \"$completed_at\"" "$yaml_file"

  duration=$(calculate_duration "$started_at" "$completed_at")
  yq e -i ".$type.duration = \"${duration}s\"" "$yaml_file"

}

calculate_duration() {
  local started_at=$1
  local completed_at=$2

  start_seconds=$(date -d "$started_at" +%s)
  end_seconds=$(date -d "$completed_at" +%s)

  duration=$((end_seconds - start_seconds))
  echo "$duration"
}

update_skipped() {
  local yaml_file=$1
  local meter_name=$2

  total_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.total" "$yaml_file")
  success_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.success" "$yaml_file")
  fail_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.fail" "$yaml_file")
  skipped_events=$((total_events - (success_events + fail_events)))

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.skipped ) = $skipped_events" "$yaml_file"
}

increase_meters_attemped() {
  local yaml_file=$1
  yq e -i ".summary.meters_attempted |= . + 1" "$yaml_file"
}

increase_meters_failed() {
  local yaml_file=$1
  yq e -i ".summary.meters_failed |= . + 1" "$yaml_file"
}

increase_meters_successful() {
  local yaml_file=$1
  yq e -i ".summary.meters_successful |= . + 1" "$yaml_file"
}

# Compare failed/successful events for meter to total
get_meter_status(){
  local yaml_file=$1
  local meter_name=$2

  total_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.total" "$yaml_file")
  success_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.success" "$yaml_file")
  fail_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.fail" "$yaml_file")

  increase_meters_attemped "$yaml_file"

  if [ $total_events -eq $success_events ] && [ $fail_events -eq 0 ]; then
    increase_meters_successful "$yaml_file"
    echo "success"

  else
    increase_meters_failed "$yaml_file"
    echo "failure"
  fi
}

export -f init_summary
export -f init_meter_summary
export -f init_event_summary
export -f append_meter
export -f append_event
export -f append_error
export -f append_timestamps
export -f update_skipped
export -f get_meter_status