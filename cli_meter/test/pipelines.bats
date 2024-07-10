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