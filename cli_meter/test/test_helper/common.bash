#!/usr/bin/env bash

_common_setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-mock/stub'
    source "$BATS_TEST_DIRNAME/../common_utils.sh"
    source "$BATS_TEST_DIRNAME/../meters/sel735/common_sel735.sh"
    # get the containing directory of this file
    # as those will point to the bats executable's location or the preprocessed file respectively
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$PROJECT_ROOT/src:$PATH"
    LOCATION="location"
    METER_TYPE="sel"
    METER_ID="meter-1234"
    TMP_DIR=$(mktemp -d)
    EVENT_ID="1234"
    METER_IP="123.123.123"
    DATA_TYPE="events"
    SYMLINK_NAME="$LOCATION-$METER_TYPE-$METER_ID-YYYYMM-$EVENT_ID"
    ZIP_FILENAME="${SYMLINK_NAME}.zip"
}

_common_teardown() {
    rm -rf "$TMP_DIR"
}