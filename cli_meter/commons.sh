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

show_help_flag() {
  download_flag=false

  if [[ "$1" == "-d" ]]; then
    download_flag=true
  fi

  log "Usage: $0 [options]"
  log ""
  log "Options:"
  log "  -c, --config <path>          Specify the path to the YML config file."
  if [[ "$download_flag" == true ]]; then
    log "  -d, --download_dir <path>    Specify the path to the download directory."
  fi
  log "  -h, --help                   Display this help message and exit."
  log ""
  log "Examples:"
  if [[ "$download_flag" == true ]]; then
    log "  $0 -c /path/to/config.yml -d /path/to/download_dir"
    log "  $0 --config /path/to/config.yml --download_dir /path/to/download_dir"
  else
    log "  $0 -c /path/to/config.yml"
    log "  $0 --config /path/to/config.yml"
  fi
  exit 0

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
