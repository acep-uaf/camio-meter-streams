#!/bin/bash
# ==============================================================================
# Script Name:        commons.sh
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
#   fail()                  - Output an error message and exit with the provided or default exit code
#   log()                   - Output a message to stderr
#   show_help_flag()        - Display usage information
#
# Requirements:       flock
# ==============================================================================

# General Execution Codes
EXIT_SUCCESS=0                # Successful completion
EXIT_UNKNOWN=1099             # Unknown error

# Argument and Configuration Errors
EXIT_NO_ARGS=1000             # No arguments provided
EXIT_INVALID_ARGS=1001        # Invalid arguments provided
EXIT_CONFIG_NOT_FOUND=1002    # Configuration file not found
EXIT_INVALID_CONFIG=1003      # Invalid or missing critical configuration values

# File and Directory Errors
EXIT_FILE_NOT_FOUND=1014      # Required file not found
EXIT_DIR_NOT_FOUND=1015       # Directory does not exist
EXIT_DIR_CREATION_FAIL=1016   # Failed to create directory
EXIT_FILE_ACCESS_FAIL=1017    # File system permission or access issue

# Network and Connection Errors
EXIT_CONNECT_FAIL=1010           # Connection to meter failed
EXIT_LFTP_FAIL=1006           # LFTP command failed

# Command Execution Errors
EXIT_RSYNC_FAIL=1005          # Rsync command failed
EXIT_LOCK_FAIL=1007           # Failed to acquire lock

# Specific Operation Errors
EXIT_DOWNLOAD_FAIL=1011       # File download failure
EXIT_VALIDATION_FAIL=1012     # Data validation failure
EXIT_ZIP_FAIL=1013            # Compression/zipping failure
EXIT_METADATA_FAIL=1018       # Metadata creation failure

# Export exit codes for use in other scripts
export EXIT_SUCCESS
export EXIT_UNKNOWN
export EXIT_NO_ARGS
export EXIT_INVALID_ARGS
export EXIT_CONFIG_NOT_FOUND
export EXIT_INVALID_CONFIG
export EXIT_FILE_NOT_FOUND
export EXIT_DIR_NOT_FOUND
export EXIT_DIR_CREATION_FAIL
export EXIT_FILE_ACCESS_FAIL
export EXIT_CONN_FAIL
export EXIT_LFTP_FAIL
export EXIT_RSYNC_FAIL
export EXIT_LOCK_FAIL
export EXIT_DOWNLOAD_FAIL
export EXIT_VALIDATION_FAIL
export EXIT_ZIP_FAIL
export EXIT_METADATA_FAIL

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
    exit $EXIT_LOCK_FAIL
}

exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

# Utility functions
fail() {
  local exit_code="${1:-$EXIT_UNKNOWN}" # default to EXIT_UNKNOWN if not provided
  local message="$2"
  echo "[ERROR] $message. Exiting with code $exit_code." >&2
  exit "$exit_code"
}

log() {
  echo "$1" >&2
}

show_help_flag() {
  log "Usage: $0 [options]"
  log ""
  log "Options:"
  log "  -c, --config <path>          Specify the path to the YML config file."
  log "  -h, --help                   Display this help message and exit."
  log ""
  log "Examples:"
  log "  $0 -c /path/to/config.yml"
  log "  $0 --config /path/to/config.yml"
  log ""
  fail $EXIT_INVALID_ARGS "Invalid arguments provided"
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
