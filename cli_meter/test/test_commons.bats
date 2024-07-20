#!/usr/bin/env bats

setup() {
  load 'test_helper/common'
  _common_setup
}

teardown() {
    _common_teardown
}

#################### Test cases for common_utils.sh ####################
@test "log function outputs message to stderr" {
  run log "Test log message"
  assert_success
  assert_output "Test log message"
}

#################### Test cases for common_sel735.sh ####################
@test "mark_event_incomplete function moves the event directory to .incomplete" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  assert_success
  assert_output --partial "Moved event $EVENT_ID to $EVENT_ID.incomplete_1"
  assert [ -d "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_1" ]
  assert [ ! -d "$TMP_DIR/$DATE_DIR/$EVENT_ID" ]
}

@test "mark_event_incomplete function directory doesn't exit" {
  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  assert_success
  assert_output --partial "[ERROR] Directory $TMP_DIR/$DATE_DIR/$EVENT_ID does not exist."
}

@test "mark_event_incomplete function rotate directories" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  for i in {1..5}; do
    mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_$i"
  done

  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  assert_success
  assert_output --partial "Rotated $TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_5 to $TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_4"
  assert [ ! -d "$TMP_DIR/$DATE_DIR/$EVENT_ID" ]

  for i in {1..5}; do
    assert [ -d "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_$i" ]
  done
}

#TODO: Can I use mock or stub here to create a fake directory to mock mark_event_incomplete function?
@test "handle_sig function moves the current_event_id directory to .incomplete" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  current_event_id="$EVENT_ID"
  base_output_dir="$TMP_DIR"
  run handle_sig SIGINT
  assert_failure 130
  assert_output --partial "130"
}

@test "handle_sig function no current_event_id set and no dir to move .incomplete" {
  current_event_id=""
  base_output_dir="$TMP_DIR"
  run handle_sig SIGINT
  assert_failure 130
  assert_output --partial "No download in progress, no event to move to .incomplete"
}


# Helper function to create expected event files
create_event_files() {
  local event_dir=$1
  local event_id=$2
  local expected_files=("CEV_${event_id}.CEV" "HR_${event_id}.CFG" "HR_${event_id}.DAT" "HR_${event_id}.HDR" "HR_${event_id}.ZDAT")

  mkdir -p "$event_dir"
  for file in "${expected_files[@]}"; do
    touch "${event_dir}/${file}"
  done
}

# Helper function to create metadata files
create_metadata_files() {
  local event_dir=$1
  local event_id=$2
  local metadata_files=("${event_id}_metadata.yml" "checksum.md5")

  for file in "${metadata_files[@]}"; do
    touch "${event_dir}/${file}"
  done
}

@test "validate_complete_directory passes when all files are present" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  create_metadata_files "$EVENT_DIR" "$EVENT_ID"

  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  assert_success
}

@test "validate_complete_directory fails when metadata file is missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  create_metadata_files "$EVENT_DIR" "$EVENT_ID"
  rm "$EVENT_DIR/${EVENT_ID}_metadata.yml"

  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  assert_failure
  assert_output --partial "Missing metadata file: ${EVENT_ID}_metadata.yml in directory: $EVENT_DIR"
}

@test "validate_complete_directory fails when metadata files are missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  touch "$EVENT_DIR/${EVENT_ID}_metadata.yml"
  # Missing checksum.md5

  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  assert_failure
  assert_output --partial "Missing metadata file: checksum.md5 in directory: $EVENT_DIR"
}

@test "validate_complete_directory fails when directory does not exist" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  assert_failure
}

@test "validate_download function passes when all files are present" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  mkdir -p "$EVENT_DIR"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  run validate_download "$EVENT_DIR" "$EVENT_ID"
  assert_success
}

@test "validate_download function fails when a file is missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  rm "$EVENT_DIR/HR_${EVENT_ID}.ZDAT" # Remove .ZDAT file

  run validate_download "$EVENT_DIR" "$EVENT_ID"
  assert_failure
  assert_output --partial "Missing file: HR_${EVENT_ID}.ZDAT in directory: $EVENT_DIR"
}

@test "generate_date_dir function returns the correct date directory" {
  run generate_date_dir 2021 10
  assert_success
  assert_output "2021-10"
}

@test "generate_date_dir function returns the correct date directory with leading zero" {
  run generate_date_dir 2021 01
  assert_success
  assert_output "2021-01"
}

@test "calculate_max_date function returns the correct date" {
  run calculate_max_date 5
  assert_success
  assert_output "$(date -d "5 days ago" +%Y-%m-%d)"
}

@test "calculate_max_date function returns the correct date for 1 day" {
  run calculate_max_date 1
  assert_success
  assert_output "$(date -d "1 days ago" +%Y-%m-%d)"
}

@test "calculate_max_date function returns the correct date for 10 days" {
  run calculate_max_date 10
  assert_success
  assert_output "$(date -d "10 days ago" +%Y-%m-%d)"
}


