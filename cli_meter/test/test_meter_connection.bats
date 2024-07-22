#!/usr/bin/env bats
# Use this script to test functions/scripts in /cli_meter directory
SCRIPT_DIR="meters/sel735"
setup() {
    load 'test_helper/common'
    _common_setup
    cd $SCRIPT_DIR
}

teardown() {
    _common_teardown
}

@test "test_meter_connection.sh shows usage for no arguments" {
    run ./test_meter_connection.sh
    assert_failure
    assert_output --partial "[ERROR] Usage: test_meter_connection.sh <meter_ip> [bandwidth_limit] [max_retries]. Exit code: $STREAMS_INVALID_ARGS"
}
