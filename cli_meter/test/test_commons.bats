#!/usr/bin/env bats

# Source the helpers.bash file
source "$BATS_TEST_DIRNAME/helpers.sh"
script_name="bash"
EVENT_ID="1234"
DATE_DIR="2021-01"

setup() {
  load 'test/libs/bats-assert/load.bash' 
  load 'test/libs/bats-support/load.bash'
  load "$BATS_TEST_DIRNAME/../common_utils.sh"
  load "$BATS_TEST_DIRNAME/../meters/sel735/common_sel735.sh"
  # Create a temporary directory for testing
  TMP_DIR=$(mktemp -d)
}

teardown() {
  # Remove the temporary directory after testing
  rm -rf "$TMP_DIR"
}


#################### Test cases for common_utils.sh ####################
@test "fail function outputs error message and exits with status 1099" {
  run bash -c "fail 1099 'Test error message'"
  [ "$status" -ne 0 ]
  [[ "$output" == "[ERROR] Test error message. Exit code: 1099" ]]
}

@test "log function outputs message to stderr" {
  run bash -c "log 'Test log message'"
  [ "$status" -eq 0 ]
  echo "$output"
  [[ "$output" == "Test log message" ]]
}

#################### Test cases for common_sel735.sh ####################
@test "mark_event_incomplete function moves the event directory to .incomplete" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Moved event $EVENT_ID to $EVENT_ID.incomplete_" ]]
  assert [ -d "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_1" ]
  assert [ ! -d "$TMP_DIR/$DATE_DIR/$EVENT_ID" ]
}

@test "mark_event_incomplete function directory doesn't exit" {
  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  [ "$status" -eq 0 ]
  [[ "$output" =~ "[ERROR] Directory $TMP_DIR/$DATE_DIR/$EVENT_ID does not exist." ]]
}

@test "mark_event_incomplete function rotate directories" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  for i in {1..5}; do
    mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_$i"
  done

  run mark_event_incomplete "$EVENT_ID" "$TMP_DIR/$DATE_DIR"   
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Rotated $TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_5 to $TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_4" ]]
  
  assert [ ! -d "$TMP_DIR/$DATE_DIR/$EVENT_ID" ]

  for i in {1..5}; do
    assert [ -d "$TMP_DIR/$DATE_DIR/$EVENT_ID.incomplete_$i" ]
  done
}

#TODO: Can I use mock or stub here to create a fake directory to mock mark_event_incomplete function?
@test "handle_sigint function moves the current_event_id directory to .incomplete" {
  mkdir -p "$TMP_DIR/$DATE_DIR/$EVENT_ID"
  current_event_id="$EVENT_ID"
  base_output_dir="$TMP_DIR"
  run handle_sigint
  [ "$status" -eq 130 ]
  [[ "$output" =~ "Download in progress, moving event $EVENT_ID to .incomplete" ]]
}

@test "handle_sigint function no current_event_id set and no dir to move .incomplete" {
  current_event_id=""
  base_output_dir="$TMP_DIR"
  run handle_sigint
  [ "$status" -eq 130 ]
  [[ "$output" =~ "No download in progress, no event to move to .incomplete" ]]
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
  [ "$status" -eq 0 ]
}

@test "validate_complete_directory fails when event files are missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  rm "$EVENT_DIR/HR_${EVENT_ID}.ZDAT"
  # Missing HR_${EVENT_ID}.ZDAT

  create_metadata_files "$EVENT_DIR" "$EVENT_ID"

  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing file: HR_${EVENT_ID}.ZDAT in directory: $EVENT_DIR" ]]
}

@test "validate_complete_directory fails when metadata files are missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  touch "$EVENT_DIR/${EVENT_ID}_metadata.yml"
  # Missing checksum.md5

  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing metadata file: checksum.md5 in directory: $EVENT_DIR" ]]
}

@test "validate_complete_directory fails when directory does not exist" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  run validate_complete_directory "$EVENT_DIR" "$EVENT_ID"
  [ "$status" -eq 1 ]
}

@test "validate_download function passes when all files are present" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  mkdir -p "$EVENT_DIR"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  run validate_download "$EVENT_DIR" "$EVENT_ID"
  [ "$status" -eq 0 ]
}

@test "validate_download function fails when a file is missing" {
  EVENT_DIR="$TMP_DIR/$DATE_DIR/$EVENT_ID"
  create_event_files "$EVENT_DIR" "$EVENT_ID"
  rm "$EVENT_DIR/HR_${EVENT_ID}.ZDAT" # Remove .ZDAT file

  run validate_download "$EVENT_DIR" "$EVENT_ID"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Missing file: HR_${EVENT_ID}.ZDAT in directory: $EVENT_DIR" ]]
}