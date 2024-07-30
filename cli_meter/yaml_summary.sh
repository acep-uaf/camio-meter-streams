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


# init_summary function modified to set SUMMARY_FILE and create the required directory structure
init_summary() {
  local output_dir=$1
  local started_at=$2
  local meters_total=$3
  local year_month=$(date -d "$started_at" +"%Y-%m")
  local dir="$output_dir/summary/$year_month"
  local yaml_file="$dir/download_summary_$(date -d "$started_at" +"%Y%m%d_%H%M").yml"
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

  export SUMMARY_FILE="$yaml_file"
}

# Modified other functions to use SUMMARY_FILE directly
init_meter_summary() {
  local meter_name=$1
  local started_at=$2

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

  yq e -i ".meters += [$meter_template]" "$SUMMARY_FILE"

  # Insert the meter name and start time
  yq e -i "( .meters[] | select(.name == \"\") | .name ) = \"$meter_name\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .started_at ) = \"$started_at\"" "$SUMMARY_FILE"
}

init_event_summary() {
  local meter_name=$1
  local total_events=$2

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.total ) = $total_events" "$SUMMARY_FILE"
}

append_info() {
  local key=$1
  local value=$2

  yq e -i ".${key} = \"$value\"" "$SUMMARY_FILE"
}

append_meter() {
  local meter_name=$1
  local status=$2
  local started_at=$3
  local completed_at=$4

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .status) = \"$status\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .completed_at) = \"$completed_at\"" "$SUMMARY_FILE"

  started_at=$(yq e ".meters[] | select(.name == \"$meter_name\") | .started_at" "$SUMMARY_FILE")

  duration=$(calculate_duration $started_at $completed_at)
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .duration) = \"${duration}s\"" "$SUMMARY_FILE"
}

append_event() {
  local meter_name=$1
  local event_id=$2
  local event_status=$3
  local started_at=$4
  local completed_at=$5
  local total_files_size=$6
  local exit_code=${7:-}
  local message=${8:-}

  # Add the events array if it doesn't exist
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) = ( .meters[] | select(.name == \"$meter_name\") | .events // [] )" "$SUMMARY_FILE"

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
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events ) += [$event_template]" "$SUMMARY_FILE"

  # Insert status into the event template
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].status ) = \"$event_status\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].started_at ) = \"$started_at\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].completed_at ) = \"$completed_at\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].duration ) = \"${duration}s\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].download_size ) = \"${total_files_size}KB\"" "$SUMMARY_FILE"
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].download_speed ) = \"${download_speed}KBps\"" "$SUMMARY_FILE"

  if [ "$event_status" == "success" ]; then
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.success ) |= . + 1" "$SUMMARY_FILE"
  else
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.fail ) |= . + 1" "$SUMMARY_FILE"
    yq e -i "( .meters[] | select(.name == \"$meter_name\") | .events[-1].message ) = \"$message\"" "$SUMMARY_FILE"
  fi
}

append_error() {
  local meter_name=$1
  local exit_code=$2
  local message=$3

  # Add the errors array if it doesn't exist
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors ) = ( .meters[] | select(.name == \"$meter_name\") | .errors // [] )" "$SUMMARY_FILE"

  # Create the error template
  error_template="{
    \"exit_code\": $exit_code,
    \"message\": \"\"
  }"

  # Append the error to the specified meter's errors array
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors ) += [$error_template]" "$SUMMARY_FILE"

  # Insert message into the error template
  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .errors[-1].message ) = \"$message\"" "$SUMMARY_FILE"
}

append_timestamps() {
  local started_at=$1
  local completed_at=$2
  local type=$3

  yq e -i ".$type.started_at = \"$started_at\"" "$SUMMARY_FILE"
  yq e -i ".$type.completed_at = \"$completed_at\"" "$SUMMARY_FILE"

  duration=$(calculate_duration "$started_at" "$completed_at")
  yq e -i ".$type.duration = \"${duration}s\"" "$SUMMARY_FILE"
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
  local meter_name=$1

  total_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.total" "$SUMMARY_FILE")
  success_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.success" "$SUMMARY_FILE")
  fail_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.fail" "$SUMMARY_FILE")
  skipped_events=$((total_events - (success_events + fail_events)))

  yq e -i "( .meters[] | select(.name == \"$meter_name\") | .downloads.skipped ) = $skipped_events" "$SUMMARY_FILE"
}

increase_meters_attempted() {
  yq e -i ".summary.meters_attempted |= . + 1" "$SUMMARY_FILE"
}

increase_meters_failed() {
  yq e -i ".summary.meters_failed |= . + 1" "$SUMMARY_FILE"
}

increase_meters_successful() {
  yq e -i ".summary.meters_successful |= . + 1" "$SUMMARY_FILE"
}

# Compare failed/successful events for meter to total
get_meter_status() {
  local meter_name=$1

  total_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.total" "$SUMMARY_FILE")
  success_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.success" "$SUMMARY_FILE")
  fail_events=$(yq e ".meters[] | select(.name == \"$meter_name\") | .downloads.fail" "$SUMMARY_FILE")

  increase_meters_attempted

  if [ $total_events -eq $success_events ] && [ $fail_events -eq 0 ]; then
    increase_meters_successful
    echo "success"
  else
    increase_meters_failed
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
