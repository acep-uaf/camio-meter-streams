#!/bin/bash
# ==============================================================================
# Script Name:        common_utils.sh
# Description:        This file contains common functions used by all scripts in
#                     the Meter Event Data/Archive Pipeline.
#
# Functions:
#   _lock()                 - Apply a specified flock option to the lock file descriptor
#   _no_more_locking()      - Cleanup function: unlock and remove the lock file
#   _prepare_locking()      - Prepare the lock file and ensure cleanup runs on script exit
#   _failed_locking()       - Log message and exit if another instance is already running
#   exlock_now()            - Obtain an exclusive lock immediately or fail
#   exlock()                - Obtain an exclusive lock
#   shlock()                - Obtain a shared lock
#   unlock()                - Drop a lock
#   fail()                  - Output an error message and exit
#   log()                   - Output a message to stderr
#   show_help_flag()        - Display usage information
#
# Requirements:       flock
# ==============================================================================
# General Execution Codes
export EXIT_SUCCESS=0                # Successful completion
export EXIT_SIGINT=130               # Script interrupted by SIGINT (Ctrl+C)
export EXIT_UNKNOWN=1099             # Unknown error

# Argument and Configuration Errors
export EXIT_INVALID_ARGS=1000        # Invalid arguments provided
export EXIT_INVALID_CONFIG=1001      # Invalid or missing critical configuration values

# File and Directory Errors
export EXIT_FILE_NOT_FOUND=1010      # Required file not found
export EXIT_FILE_CREATION_FAIL=1011  # Failed to create file
export EXIT_DIR_NOT_FOUND=1012       # Directory does not exist
export EXIT_DIR_CREATION_FAIL=1013   # Failed to create directory

# Command Errors
export EXIT_LFTP_FAIL=1020           # LFTP command failed
export EXIT_RSYNC_FAIL=1021          # Rsync command failed

# Specific Operation Errors
export EXIT_DOWNLOAD_FAIL=1030       # File download failure
export EXIT_ZIP_FAIL=1031            # Compression/zipping failure
export EXIT_METADATA_FAIL=1032       # Metadata/Checksum creation or file generation failure
export EXIT_LOCK_FAIL=1033           # Failed to acquire lock

LOCKFD=99 # Assign a high file descriptor number for locking 

# Lock Functions
_lock()             { flock -$1 $LOCKFD; } # Lock function: apply flock with given arg to LOCKFD
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; } # Cleanup function: unlock, remove lockfile
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; } # Ensure lock cleanup runs on script exit

_failed_locking() {
    log "Another instance is already running!"
    log "Running instances (PID, Command):"
    pgrep -af "$(basename $0)" | grep -v $$ | while read pid cmd; do
        log "PID: $pid, Command: $cmd"
    done
    fail $EXIT_LOCK_FAIL
}

exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

# Utility functions
fail() {
  local exit_code="${1:-$EXIT_UNKNOWN}"
  local message="${2:-""}"

  log "[ERROR] $message. Exit code: $exit_code"
  exit $exit_code
}

log() {
  echo "$1" >&2
}

parse_config_arg() {
  local config_path=""

  # Parse command line arguments for --config/-c flags
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -c | --config)
        if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
          show_help_flag
          fail $EXIT_INVALID_ARGS "Config path not provided or invalid after -c/--config"
        fi
        config_path="$2"
        shift 2
        ;;
      -h | --help)
        show_help_flag
        exit 0
        ;;
      *)
        show_help_flag
        fail $EXIT_INVALID_ARGS "Unknown parameter: $1"
        ;;
    esac
  done

  echo "$config_path"
}

show_help_flag() {
  local script_name=$(basename "$0")
  log "Usage: ./$script_name [options]"
  log ""
  log "Options:"
  log "  -c, --config <path>          Specify the path to the YML config file."
  log "  -h, --help                   Display this help message and exit."
  log ""
  log "Examples:"
  log "  ./$script_name -c /path/to/config.yml"
  log "  ./$script_name --config /path/to/config.yml"
}

# Export functions for use in other scripts
export -f log
export -f fail
export -f show_help_flag

export -f _lock
export -f _no_more_locking
export -f _prepare_locking
export -f _failed_locking

export -f exlock_now
export -f exlock
export -f shlock
export -f unlock
