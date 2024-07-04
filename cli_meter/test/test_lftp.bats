#!/usr/bin/env bats
# Use this script to test lftp operations

setup() {
    load 'test_helper/common'
    _common_setup
    cd "meters/sel735"
    USERNAME="test"
    PASSWORD="test"
    stub lftp \
        'ls' \
        'bye'
}

teardown() {
    unstub lftp
    _common_teardown
}

@test "test_meter_connection.sh test 0 arguments" {
    run ./test_meter_connection.sh
    assert_failure $(($EXIT_INVALID_ARGS % 256))
    assert_output --partial "Usage: test_meter_connection.sh <meter_ip> [bandwidth_limit]"
}

@test "test_meter_connection.sh test 1 argument" {
    run ./test_meter_connection.sh "$METER_IP"
    assert_success
    assert_output --partial "Successful connection test to meter: $METER_IP"
}

