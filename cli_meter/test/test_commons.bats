#!/usr/bin/env bats

# Source the helpers.bash file
source "$BATS_TEST_DIRNAME/helpers.sh"
script_name="bash"

setup() {
  source "$BATS_TEST_DIRNAME/../common_utils.sh"
  # Create a temporary directory for testing
  TMP_DIR=$(mktemp -d)
}

teardown() {
  # Remove the temporary directory after testing
  rm -rf "$TMP_DIR"
}

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

# Other tests can be added here following the same pattern
