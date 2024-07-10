#!/usr/bin/env bats
# Use this script to test functions/scripts in /cli_meter directory

setup() {
    load 'test_helper/common'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "data_pipeline.sh shows usage for no arguments" {
    run ./data_pipeline.sh
    assert_failure
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] No arguments provided. Exit code: $STREAMS_INVALID_ARGS"
}

@test "data_pipeline.sh shows usage for help flags" {
    run ./data_pipeline.sh -h
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"

    run ./data_pipeline.sh --help
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"
}

@test "data_pipeline.sh fails with no config path" {
    run ./data_pipeline.sh -c
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: $STREAMS_INVALID_ARGS"

    run ./data_pipeline.sh --config
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: $STREAMS_INVALID_ARGS"
}

@test "data_pipeline.sh fails with invalid config path" {
    run ./data_pipeline.sh -c invalid_path
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"
}

@test "data_pipeline.sh fails with invalid config: no username" {
    run ./data_pipeline.sh -c test/mock/configs/config_no_username.yml
    assert_failure $(($STREAMS_INVALID_CONFIG % 256))
    assert_output --partial "[ERROR] Default username cannot be null or empty. Exit code: $STREAMS_INVALID_CONFIG"
}

@test "data_pipeline.sh fails with invalid config: no meters" {
    run ./data_pipeline.sh -c test/mock/configs/config_no_meters.yml
    assert_failure $(($STREAMS_INVALID_CONFIG % 256))
    assert_output --partial "[ERROR] Must have at least 1 meter in the config file. Exit code: $STREAMS_INVALID_CONFIG"
}

@test "data_pipeline.sh fails with invalid config: max_age_days 0" {
    run ./data_pipeline.sh -c test/mock/configs/config_max_age_0.yml
    assert_failure $(($STREAMS_INVALID_CONFIG % 256))
    assert_output --partial "[ERROR] Max age days must be an integer greater than 0:"
}