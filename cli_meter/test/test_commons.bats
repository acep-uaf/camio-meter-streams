#!/usr/bin/env bats

# Source the helpers.bash file
source "$BATS_TEST_DIRNAME/helpers.bash"

setup() {
  # Create a temporary directory for testing
  TMP_DIR=$(mktemp -d)
}

teardown() {
  # Remove the temporary directory after testing
  rm -rf "$TMP_DIR"
}

@test "fail function outputs error message and exits with status 1" {
  run bash -c "source $BATS_TEST_DIRNAME/../commons.sh; fail 'Test error message'"
  [ "$status" -ne 0 ]
  [[ "$output" == "[ERROR] Test error message" ]]
}

@test "log function outputs message to stderr" {
  run bash -c "source $BATS_TEST_DIRNAME/../commons.sh; log 'Test log message'"
  [ "$status" -eq 0 ]
  [[ "$output" == "Test log message" ]]
}

@test "parse_config_arg shows usage when no arguments are given" {
  local expected_help_msg=$(help_msg $script_name)
  run bash -c "source $BATS_TEST_DIRNAME/../commons.sh; parse_config_arg"
  [ "$status" -ne 0 ]
  echo "$output"
  echo "$expected_help_msg"
  [[ "$output" =~ "$expected_help_msg" ]]
}

# Other tests can be added here following the same pattern
