#!/bin/bash
# Function to log messages with a timestamp
# From download_by_id.sh
log1() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to log messages with a timestamp
# From update_event_files.sh
log2() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

log() {
  local LOG_LEVEL=$1
  shift
  local MESSAGE="$@"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "${TIMESTAMP} [${LOG_LEVEL}] ${MESSAGE}"
}

export -f log