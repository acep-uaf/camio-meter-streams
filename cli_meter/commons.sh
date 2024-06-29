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
#   fail()                  - Output an error message and exit
#   log()                   - Output a message to stderr
#   show_help_flag()        - Display usage information
#
# Requirements:       flock
# ==============================================================================

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
    exit 1
}

exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x; }   # obtain an exclusive lock
shlock()            { _lock s; }   # obtain a shared lock
unlock()            { _lock u; }   # drop a lock

# Utility functions
fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

log() {
  echo "$1" >&2
}

parse_config_arg() {
  [ "$#" -eq 0 ] && show_help_flag && fail "No arguments provided."
  local config_path=""

  # Parse command line arguments for --config/-c flags
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -c | --config)
        if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
          show_help_flag
          fail "Config path not provided or invalid after -c/--config"
        fi
        config_path="$2"
        shift 2
        ;;
      -h | --help)
        show_help_flag
        exit 1
        ;;
      *)
        show_help_flag
        fail "Unknown parameter: $1"
        ;;
    esac
  done

  echo "$config_path"
}

show_help_flag() {
  script_name=$(basename "$0")
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
