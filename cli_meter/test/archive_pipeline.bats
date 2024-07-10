#!/usr/bin/env bats
# Use this script to test functions/scripts in /cli_meter directory

setup() {
    load 'test_helper/common'
    _common_setup
}

teardown() {
    _common_teardown
}

@test "archive_pipeline.sh shows usage for no arguments" {
    run ./archive_pipeline.sh
    assert_failure
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] No arguments provided. Exit code: $STREAMS_INVALID_ARGS"
}

@test "archive_pipeline.sh shows usage for help flags" {
    run ./archive_pipeline.sh -h
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"

    run ./archive_pipeline.sh --help
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "Options:"
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"
}

@test "archive_pipeline.sh fails with no config path" {
    run ./archive_pipeline.sh -c
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: $STREAMS_INVALID_ARGS"

    run ./archive_pipeline.sh --config
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config path not provided or invalid after -c/--config. Exit code: $STREAMS_INVALID_ARGS"
}

@test "archive_pipeline.sh fails with invalid config path" {
    run ./archive_pipeline.sh -c invalid_path
    assert_failure $(($STREAMS_FILE_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Config file does not exist. Exit code: $STREAMS_FILE_NOT_FOUND"
}

@test "archive_pipeline.sh fails with invalid config: no host" {
    run ./archive_pipeline.sh -c test/mock/configs/archive/config_no_host.yml
    assert_failure $(($STREAMS_INVALID_CONFIG % 256))
    assert_output --partial "[ERROR] Destination host cannot be null or empty. Exit code: $STREAMS_INVALID_CONFIG"
}

@test "archive_pipeline.sh fails with invalid config: no dirs" {
    run ./archive_pipeline.sh -c test/mock/configs/archive/config_no_dirs.yml
    assert_failure $(($STREAMS_INVALID_CONFIG % 256))
    assert_output --partial "[ERROR] Source directory cannot be null or empty. Exit code: $STREAMS_INVALID_CONFIG"
}

@test "archive_pipeline.sh fails with invalid config: no src dir" {
    run ./archive_pipeline.sh -c test/mock/configs/archive/config_valid.yml
    assert_failure $(($STREAMS_DIR_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Source directory"
    assert_output --partial "doesn't exist or is empty. Exit code: $STREAMS_DIR_NOT_FOUND"
}

@test "archive_pipeline.sh fails with valid" {
    run ./archive_pipeline.sh -c test/mock/configs/archive/config_valid.yml
    assert_failure $(($STREAMS_DIR_NOT_FOUND % 256))
    assert_output --partial "[ERROR] Source directory"
    assert_output --partial "doesn't exist or is empty. Exit code: $STREAMS_DIR_NOT_FOUND"
}