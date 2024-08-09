#!/usr/bin/env bats
# Use this script to test the scripts in meters/sel735
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
    run ./create_message.sh "$EVENT_ID" "$ZIP_FILENAME" "/path/to/file" "$DATA_TYPE" "$TMP_DIR" 
    assert_success
    assert [ -f "$TMP_DIR/$ZIP_FILENAME.message" ]
}

# TODO: These tests are meant to fail and they are but not with the correct exit code.
@test "create_message.sh test 0 arguments" {
    run ./create_message.sh
    assert_failure $(($STREAMS_INVALID_ARGS % 256))
    assert_output --partial "Usage: create_message.sh <event_id> <zip_filename> <md5sum_value> <data_type> <output_dir>"
}

@test "create_message.sh test too many arguments" {
    run ./create_message.sh "$EVENT_ID" "$ZIP_FILENAME" "/path/to/file" "$DATA_TYPE"
    assert_failure $(($STREAMS_INVALID_ARGS % 256))
    assert_output --partial "Usage: create_message.sh <event_id> <zip_filename> <md5sum_value> <data_type> <output_dir>"
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

@test "zip_event.sh execution test" {
    mkdir -p "$TMP_DIR/$EVENT_ID"
    run ./zip_event.sh "$TMP_DIR" "$TMP_DIR" "$EVENT_ID" "$SYMLINK_NAME"
    assert_success
    assert_output --partial "Successfully zipped symlink: $SYMLINK_NAME to $TMP_DIR/$ZIP_FILENAME for event: $EVENT_ID"
    assert [ -f "$TMP_DIR/$ZIP_FILENAME" ]
    assert [ -d "$TMP_DIR/$EVENT_ID" ]
}

@test "zip_event.sh test 0 arguments" {
    run ./zip_event.sh
    assert_failure $(($STREAMS_INVALID_ARGS % 256))
    assert_output --partial "Usage: zip_event.sh <source_dir> <dest_dir> <event_id> <symlink_name>"
}

@test "zip_event.sh test invalid event_id" {
    run ./zip_event.sh "$TMP_DIR" "$TMP_DIR" "not_a_directory" "$SYMLINK_NAME"
    assert_failure $(($STREAMS_DIR_NOT_FOUND % 256))
}