#!/usr/bin/env bats

setup() {
  load 'test_helper/common'
  _common_setup
}

teardown() {
    _common_teardown
}

@test "failure function with no arguments" {
  run failure
  assert_failure $STREAMS_UNKNOWN
  assert_output "[ERROR] . Exit code: $STREAMS_UNKNOWN"
}

@test "failure function with exit code" {
  run failure $STREAMS_INVALID_ARGS
  assert_failure $STREAMS_INVALID_ARGS
  assert_output "[ERROR] . Exit code: $STREAMS_INVALID_ARGS"
}

@test "failure function with exit code and message" {
  run failure $STREAMS_INVALID_ARGS "Invalid arguments"
  assert_failure $STREAMS_INVALID_ARGS
  assert_output "[ERROR] Invalid arguments. Exit code: $STREAMS_INVALID_ARGS"
}

@test "warning function with no message" {
  run warning
  assert_success
  assert_output "[WARNING] "
}

@test "warning function with message" {
  run warning "This is a warning message"
  assert_success
  assert_output "[WARNING] This is a warning message"
}

@test "log function with no message" {
  run log
  assert_success
  assert_output ""
}

@test "log function with message" {
  run log "Test log message"
  assert_success
  assert_output "Test log message"
}

@test "log function with 2 messages" {
  run log "Test log message" "Another log message"
  assert_success
  assert_output "Test log message"
}
