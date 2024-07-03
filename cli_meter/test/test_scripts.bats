#!/usr/bin/env bats

EVENT_ID="1234"
METER_IP="123.123.123"
DATA_TYPE="events"
SCRIPT_DIR="meters/sel735"

setup() {
    load 'test_helper/common'
    _common_setup
    cd $SCRIPT_DIR
}

teardown() {
    _common_teardown
}

@test "create_message.sh execution test" {
    run ./create_message.sh "$EVENT_ID" "$EVENT_ID.zip" "/path/to/file" "$DATA_TYPE" "$TMP_DIR" 
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
    for i in {1..3}; do
        mkdir -p "$TMP_DIR/$EVENT_ID.incomplete_$i"
    done
    
    run ./cleanup_incomplete.sh "$TMP_DIR"
    assert_success 
    for i in {1..3}; do
        assert [ ! -d "$TMP_DIR/$EVENT_ID.incomplete_$i" ]
    done
}