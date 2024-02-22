#!/bin/bash

log() {
    local LOG_DIR="logs"
    mkdir -p "$LOG_DIR"

    local DEFAULT_LOG_FILE="default.log"
    local MESSAGE=$1
    local LOG_LEVEL=${2-"INFO"}
    local LOG_FILE=$LOG_DIR/${3:-default.log}
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "${TIMESTAMP} [${LOG_LEVEL}] ${MESSAGE}" >> "$LOG_FILE"
}

export -f log