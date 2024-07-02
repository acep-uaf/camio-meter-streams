#!/usr/bin/env bats

# Source the helpers.bash file
source "$BATS_TEST_DIRNAME/helpers.sh"
script_name="data_pipeline.sh"

setup() {
  # Create a temporary directory for testing
  TMP_DIR=$(mktemp -d)
}

teardown() {
  # Remove the temporary directory after testing
  rm -rf "$TMP_DIR"
}

@test "data_pipeline.sh shows usage for no arguments" {
    local expected_help_msg=$(help_msg $script_name)
    run "$BATS_TEST_DIRNAME/../../cli_meter/data_pipeline.sh"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "$expected_help_msg" ]]
    [[ "${lines[-1]}" =~ "[ERROR] No arguments provided. Exit code: 1000" ]]
}

@test "data_pipeline.sh shows usage for help flags" {
    local expected_help_msg=$(help_msg $script_name)
    run "$BATS_TEST_DIRNAME/../../cli_meter/data_pipeline.sh" -h
    [ "$status" -ne 0 ]
    [[ "$output" =~ "$expected_help_msg" ]]

    run "$BATS_TEST_DIRNAME/../../cli_meter/data_pipeline.sh" --help
    [ "$status" -ne 0 ]
    [[ "$output" =~ "$expected_help_msg" ]]
}

@test "data_pipeline.sh fails with no config path" {
    local expected_help_msg=$(help_msg $script_name)
    run "$BATS_TEST_DIRNAME/../../cli_meter/data_pipeline.sh" -c 
    [[ "$output" =~ "$expected_help_msg" ]]
    [[ "$output" =~ "[ERROR] Config path not provided or invalid after -c/--config. Exit code: 1000" ]]
}

@test "data_pipeline.sh fails with invalid config path" {
    run "$BATS_TEST_DIRNAME/../../cli_meter/data_pipeline.sh" -c invalid_path
    [ "$status" -ne 0 ]
    [[ "$output" =~ "[ERROR] Config file does not exist. Exit code: 1010" ]]
}


