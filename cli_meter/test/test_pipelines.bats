#!/usr/bin/env bats
# Use this script to test functions/scripts in /cli_meter directory
EVENT_ID="1234"
METER_IP="123.123.123"
script_name="bash"
SCRIPT_DIR="$BATS_TEST_DIRNAME/.."

load 'test/test_helper/bats-support/load.bash'
load 'test/test_helper/bats-assert/load.bash'

setup() {
  cd "$SCRIPT_DIR"
  source "$SCRIPT_DIR/common_utils.sh"
  TMP_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TMP_DIR"
}

@test "data_pipeline.sh shows usage for no arguments" {
    run ./data_pipeline.sh
    assert_failure
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] No arguments provided. Exit code: 1000"
}

@test "data_pipeline.sh shows usage for help flags" {
    run ./data_pipeline.sh -h
    assert_failure
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: 1010"


    run ./data_pipeline.sh --help
    assert_failure
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: 1010"
}

@test "data_pipeline.sh fails with no config path" {
    run ./data_pipeline.sh -c
    assert_failure
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: 1000"

    run ./data_pipeline.sh --config
    assert_failure
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: 1000"
}

@test "data_pipeline.sh fails with invalid config path" {
    run ./data_pipeline.sh -c invalid_path
    assert_failure
    assert_output --partial "[ERROR] Config file does not exist. Exit code: 1010"
}