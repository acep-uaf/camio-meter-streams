#!/usr/bin/env bats

EVENT_ID="1234"
METER_IP="123.123.123"
SCRIPT_DIR="$BATS_TEST_DIRNAME/../meters/sel735"

load 'test/test_helper/bats-support/load.bash'
load 'test/test_helper/bats-assert/load.bash'

setup() {
    source "$BATS_TEST_DIRNAME/../common_utils.sh"
    cd "$SCRIPT_DIR"
    source common_sel735.sh
    TMP_DIR=$(mktemp -d)
}

teardown() {
    rm -rf "$TMP_DIR"
}

@test "create_message.sh execution test" {
    run ./create_message.sh "$EVENT_ID" "$EVENT_ID.zip" "/path/to/file" "events" "$TMP_DIR" 
    assert_success
    assert [ -f "$TMP_DIR/$EVENT_ID.zip.message" ]
}

# TODO: These tests are meant to fail and they are but not with the correct exit code.
@test "create_message.sh test 0 arguments" {
    run ./create_message.sh
    assert_failure
    assert_output --partial "Usage: create_message.sh <id> <zip_filename> <path> <data_type> <output_dir>"
}

@test "create_message.sh test 2 arguments" {
    run ./create_message.sh "$EVENT_ID" "$EVENT_ID.zip"
    assert_failure
    assert_output --partial "Usage: create_message.sh <id> <zip_filename> <path> <data_type> <output_dir>"
}

@test "cleanup_incomplete.sh cleanups incomplete directories" {
    mkdir -p "$TMP_DIR/1.incomplete_1"
    mkdir -p "$TMP_DIR/1.incomplete_2"
    mkdir -p "$TMP_DIR/1.incomplete_3"
    
    run ./cleanup_incomplete.sh "$TMP_DIR"
    assert_success 
    assert [ ! -d "$TMP_DIR/1.incomplete_1" ]
    assert [ ! -d "$TMP_DIR/1.incomplete_2" ]
    assert [ ! -d "$TMP_DIR/1.incomplete_3" ]
}