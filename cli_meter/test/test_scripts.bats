#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME/helpers.sh"

setup() {
    load 'test/libs/bats-assert/load.bash' 
    load 'test/libs/bats-support/load.bash'
    source "$BATS_TEST_DIRNAME/../common_utils.sh"
    TMP_DIR=$(mktemp -d)
}

teardown() {
    # Remove the temporary directory after testing
    rm -rf "$TMP_DIR"
}
@test "create_message.sh execution test" {
    run "$BATS_TEST_DIRNAME/../../cli_meter/meters/sel735/create_message.sh" "1000" "1000.zip" "/path/to/file" "events" "$TMP_DIR" 
    [ "$status" -eq 0 ]
    assert [ -f "$TMP_DIR/1000.zip.message" ]
}

# TODO: These tests are meant to fail and they are but not with the correct exit code.
@test "create_message.sh test 0 arguments" {
    run "$BATS_TEST_DIRNAME/../../cli_meter/meters/sel735/create_message.sh"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Usage: create_message.sh <id> <zip_filename> <path> <data_type> <output_dir>" ]]
}

@test "create_message.sh test 2 arguments" {
    run "$BATS_TEST_DIRNAME/../../cli_meter/meters/sel735/create_message.sh" "1000" "1000.zip"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Usage: create_message.sh <id> <zip_filename> <path> <data_type> <output_dir>" ]]
}

@test "cleanup_incomplete.sh cleanups incomplete directories" {
    mkdir -p "$TMP_DIR/1.incomplete_1"
    mkdir -p "$TMP_DIR/1.incomplete_2"
    mkdir -p "$TMP_DIR/1.incomplete_3"
    
    run "$BATS_TEST_DIRNAME/../../cli_meter/meters/sel735/cleanup_incomplete.sh" "$TMP_DIR"
    [ "$status" -eq 0 ]
    assert [ ! -d "$TMP_DIR/1.incomplete_1" ]
    assert [ ! -d "$TMP_DIR/1.incomplete_2" ]
    assert [ ! -d "$TMP_DIR/1.incomplete_3" ]

}